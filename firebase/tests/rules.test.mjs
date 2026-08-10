import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const projectId = 'demo-hydrostack-rules-test';
let testEnv;

const commandEnvelope = (
  uid,
  commandId = 'cmd-0001',
  value = true,
  issuedAt = Date.now(),
) => ({
  commandId,
  value,
  issuedAt,
  ttlMs: 10000,
  requestedBy: uid,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
    database: {
      rules: readFileSync('../database.rules.json', 'utf8'),
    },
    storage: {
      rules: readFileSync('../storage.rules', 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearDatabase();

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    const database = context.database();

    await firestore.doc('devices/DEV-A').set({
      deviceId: 'DEV-A',
      ownerUid: 'user-a',
      alias: 'Torre A',
      status: 'offline',
      createdAt: new Date('2026-08-10T00:00:00Z'),
      claimedAt: new Date('2026-08-10T00:00:00Z'),
    });
    await firestore.doc('devices/DEV-B').set({
      deviceId: 'DEV-B',
      ownerUid: 'user-b',
      alias: 'Torre B',
      status: 'offline',
      createdAt: new Date('2026-08-10T00:00:00Z'),
      claimedAt: new Date('2026-08-10T00:00:00Z'),
    });
    await firestore.doc('devices/BAD-PATH').set({
      deviceId: 'OTHER-ID',
      ownerUid: 'user-a',
      alias: 'Inconsistente',
      status: 'offline',
    });

    await database.ref('deviceAccess/user-a/DEV-A').set(true);
    await database.ref('deviceAccess/user-b/DEV-B').set(true);
  });
});

after(async () => {
  await testEnv.cleanup();
});

test('CASO 1: usuario A puede leer su dispositivo A', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(db.doc('devices/DEV-A').get());
});

test('CASO 2: usuario A no puede leer dispositivo B', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(db.doc('devices/DEV-B').get());
});

test('CASO 3: usuario A puede crear comando y puntero de A', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-0001';
  await assertSucceeds(
    db.ref(`dispositivos/DEV-A/comandos/bomba/${id}`).set(
      commandEnvelope('user-a', id),
    ),
  );
  await assertSucceeds(
    db.ref('dispositivos/DEV-A/commandPointers/bomba').set(id),
  );
});

test('CASO 4: usuario A no puede crear comandos de B', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-0002';
  await assertFails(
    db.ref(`dispositivos/DEV-B/comandos/bomba/${id}`).set(
      commandEnvelope('user-a', id),
    ),
  );
});

test('CASO 5: usuario no autenticado no puede controlar dispositivos', async () => {
  const db = testEnv.unauthenticatedContext().database();
  const id = 'cmd-0003';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set(
      commandEnvelope('user-a', id),
    ),
  );
});

test('CASO 6: cliente no puede autoasignarse un deviceId creando ownership', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(db.doc('devices/DEV-X').set({
    deviceId: 'DEV-X',
    ownerUid: 'user-a',
    alias: 'Intento de claim',
    status: 'offline',
  }));
});

test('CASO 7: usuario A no puede cambiar ownerUid de A a B', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(db.doc('devices/DEV-A').update({ ownerUid: 'user-b' }));
});

test('comando creado es inmutable', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-immutable';
  const ref = db.ref(`dispositivos/DEV-A/comandos/luz/${id}`);
  await assertSucceeds(ref.set(commandEnvelope('user-a', id, true)));
  await assertFails(ref.child('value').set(false));
  await assertFails(ref.update({ value: false }));
  await assertFails(ref.remove());
});

test('puntero no puede referenciar un comando inexistente', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/commandPointers/bomba').set('cmd-missing'),
  );
});

test('puntero solo puede referenciar una orden del usuario autenticado', async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.database();
    const id = 'cmd-foreign';
    await db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set(
      commandEnvelope('user-b', id),
    );
  });

  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/commandPointers/luz').set('cmd-foreign'),
  );
});

test('requestedBy debe coincidir con auth.uid', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-ownerx';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set(
      commandEnvelope('user-b', id),
    ),
  );
});

test('commandId interno debe coincidir con la clave RTDB', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/luz/cmd-path1').set(
      commandEnvelope('user-a', 'cmd-other1'),
    ),
  );
});

test('commandId fuera del tamaño aceptado es rechazado', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const shortId = 'short';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${shortId}`).set(
      commandEnvelope('user-a', shortId),
    ),
  );
});

test('commandId con delimitador UART es rechazado', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const unsafeId = 'bad|id001';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${unsafeId}`).set(
      commandEnvelope('user-a', unsafeId),
    ),
  );
});

test('issuedAt futuro es rechazado por reloj servidor', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-future';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set(
      commandEnvelope('user-a', id, true, Date.now() + 60000),
    ),
  );
});

test('issuedAt demasiado antiguo es rechazado', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-old001';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set(
      commandEnvelope('user-a', id, true, Date.now() - 60000),
    ),
  );
});

test('TTL fuera del rango permitido es rechazado', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-ttl001';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set({
      ...commandEnvelope('user-a', id),
      ttlMs: 60000,
    }),
  );
});

test('bomba y nutrientes solo aceptan value=true', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const pumpId = 'cmd-pump01';
  const nutrientId = 'cmd-nut001';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/bomba/${pumpId}`).set(
      commandEnvelope('user-a', pumpId, false),
    ),
  );
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/nutrientes/${nutrientId}`).set(
      commandEnvelope('user-a', nutrientId, false),
    ),
  );
});

test('campos extra en el sobre de comando son rechazados', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-extra1';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/luz/${id}`).set({
      ...commandEnvelope('user-a', id),
      admin: true,
    }),
  );
});

test('cliente no puede crear su propia proyección deviceAccess', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(db.ref('deviceAccess/user-a/DEV-X').set(true));
});

test('cliente no puede escribir un actuador fuera del contrato', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-reboot';
  await assertFails(
    db.ref(`dispositivos/DEV-A/comandos/reiniciar/${id}`).set(
      commandEnvelope('user-a', id),
    ),
  );
});

test('cliente no puede escribir commandAcks', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  const id = 'cmd-ack001';
  await assertFails(
    db.ref(`dispositivos/DEV-A/commandAcks/bomba/${id}`).set({
      commandId: id,
      status: 'APPLIED',
      code: 'OK',
      at: Date.now(),
    }),
  );
});

test('perfil no puede apuntar deviceId a un dispositivo ajeno', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(db.doc('usuarios/user-a').set({
    uid: 'user-a',
    email: 'a@example.test',
  }));
  await assertFails(db.doc('usuarios/user-a').update({ deviceId: 'DEV-B' }));
});

test('perfil puede guardar como preferencia un deviceId realmente propio', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(db.doc('usuarios/user-a').set({
    uid: 'user-a',
    email: 'a@example.test',
  }));
  await assertSucceeds(db.doc('usuarios/user-a').update({ deviceId: 'DEV-A' }));
});

test('documento con deviceId interno distinto de la ruta no es autorizable', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertFails(db.doc('devices/BAD-PATH').get());
});

test('owner puede cambiar alias pero no status', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(db.doc('devices/DEV-A').update({
    alias: 'Torre cocina',
    updatedAt: new Date('2026-08-10T01:00:00Z'),
  }));
  await assertFails(db.doc('devices/DEV-A').update({ status: 'online' }));
});
