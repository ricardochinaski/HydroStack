import { readFileSync } from 'node:fs';
import { after, before, beforeEach, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const projectId = 'hydrostack-rules-test';
let testEnv;

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

    await database.ref('deviceAccess/user-a/DEV-A').set(true);
    await database.ref('deviceAccess/user-b/DEV-B').set(true);
    await database.ref('dispositivos/DEV-A/comandos').set({
      luz: false,
      auxiliar: false,
      bomba: false,
      nutrientes: false,
    });
    await database.ref('dispositivos/DEV-B/comandos').set({
      luz: false,
      auxiliar: false,
      bomba: false,
      nutrientes: false,
    });
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

test('CASO 3: usuario A puede escribir comandos de A', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertSucceeds(db.ref('dispositivos/DEV-A/comandos/bomba').set(true));
});

test('CASO 4: usuario A no puede escribir comandos de B', async () => {
  const db = testEnv.authenticatedContext('user-a').database();
  await assertFails(db.ref('dispositivos/DEV-B/comandos/bomba').set(true));
});

test('CASO 5: usuario no autenticado no puede controlar dispositivos', async () => {
  const db = testEnv.unauthenticatedContext().database();
  await assertFails(db.ref('dispositivos/DEV-A/comandos/luz').set(true));
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
  const admin = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(admin.doc('usuarios/user-a').set({
    uid: 'user-a',
    email: 'a@example.test',
  }));
  await assertFails(admin.doc('usuarios/user-a').update({ deviceId: 'DEV-B' }));
});

test('perfil puede guardar como preferencia un deviceId realmente propio', async () => {
  const db = testEnv.authenticatedContext('user-a').firestore();
  await assertSucceeds(db.doc('usuarios/user-a').set({
    uid: 'user-a',
    email: 'a@example.test',
  }));
  await assertSucceeds(db.doc('usuarios/user-a').update({ deviceId: 'DEV-A' }));
});
