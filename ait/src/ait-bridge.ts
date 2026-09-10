import {
  Accuracy,
  Device,
  TossPay,
  appLogin,
} from '@apps-in-toss/web-framework';

type AitBridge = {
  openCamera: (options?: { base64?: boolean; maxWidth?: number }) => Promise<unknown>;
  getPhotos: (options?: {
    base64?: boolean;
    maxCount?: number;
    maxWidth?: number;
  }) => Promise<unknown>;
  getLocation: () => Promise<unknown>;
  authorizeTossPay: (payToken: string) => Promise<unknown>;
  login: () => Promise<unknown>;
};

const bridge: AitBridge = {
  openCamera: (options) =>
    Device.openCamera({
      base64: options?.base64 ?? true,
      maxWidth: options?.maxWidth ?? 1024,
    }),
  getPhotos: (options) =>
    Device.getPhotos({
      base64: options?.base64 ?? true,
      maxCount: options?.maxCount ?? 10,
      maxWidth: options?.maxWidth ?? 1024,
    }),
  getLocation: () => Device.getLocation({ accuracy: Accuracy.Balanced }),
  authorizeTossPay: (payToken) => TossPay.authorize({ payToken }),
  login: () => appLogin(),
};

Object.defineProperty(window, 'aitBridge', {
  configurable: false,
  enumerable: false,
  value: bridge,
  writable: false,
});
