import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const projectId = 'demo-hydrostack-rules-test';
let testEnv;

const commandEnvelope = (uid, commandId = 'cmd-001', value = true) => ({
  commandId,
  value,
  issuedAt: Date.now(),
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

test('CASO 3: usuario A puede escribir un comando v2 de A', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertSucceeds(
    db.ref('dispositivos/DEV-A/comandos/bomba').set(
      commandEnvelope('user-a'),
    ),
  );
});

test('CASO 4: usuario A no puede escribir comandos de B', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-B/comandos/bomba').set(
      commandEnvelope('user-a'),
    ),
  );
});

test('CASO 5: usuario no autenticado no puede controlar dispositivos', async () => {
  const db = testEnv.unauthenticatedContext().database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/luz').set(
      commandEnvelope('user-a'),
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

test('cliente no puede crear su propia proyección deviceAccess', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(db.ref('deviceAccess/user-a/DEV-X').set(true));
});

test('cliente no puede escribir un actuador fuera del contrato', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/reiniciar').set(
      commandEnvelope('user-a'),
    ),
  );
});

test('cliente no puede borrar un slot de comando', async () => {
  const adminDb = await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.database();
    await db.ref('dispositivos/DEV-A/comandos/bomba').set(
      commandEnvelope('user-a'),
    );
    return db;
  });
  void adminDb;

  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(db.ref('dispositivos/DEV-A/comandos/bomba').remove());
});

test('requestedBy debe coincidir con auth.uid', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/luz').set(
      commandEnvelope('user-b'),
    ),
  );
});

test('TTL fuera del rango permitido es rechazado', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/luz').set({
      ...commandEnvelope('user-a'),
      ttlMs: 60000,
    }),
  );
});

test('bomba y nutrientes solo aceptan value=true', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/bomba').set(
      commandEnvelope('user-a', 'cmd-false', false),
    ),
  );
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/nutrientes').set(
      commandEnvelope('user-a', 'cmd-false-2', false),
    ),
  );
});

test('campos extra en el sobre de comando son rechazados', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/comandos/luz').set({
      ...commandEnvelope('user-a'),
      admin: true,
    }),
  );
});

test('cliente no puede escribir commandAcks', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(
    db.ref('dispositivos/DEV-A/commandAcks/bomba').set({
      commandId: 'cmd-001',
      status: 'APPLIED',
      code: 'OK',
      at: Date.now(),
    }),
  );
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
