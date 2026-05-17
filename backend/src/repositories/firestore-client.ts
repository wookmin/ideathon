import { Firestore } from '@google-cloud/firestore';

let firestore: Firestore | undefined;

export function getFirestoreClient() {
  firestore ??= new Firestore();
  return firestore;
}
