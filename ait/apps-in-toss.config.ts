import { defineConfig } from '@apps-in-toss/web-framework/config';

export default defineConfig({
  // 앱인토스 콘솔의 appName과 반드시 같게 바꿔주세요.
  appName: 'mumchit',
  brand: {
    primaryColor: '#0F6DF3',
  },
  permissions: [
    { name: 'camera', access: 'access' },
    { name: 'photos', access: 'read' },
    { name: 'geolocation', access: 'access' },
  ],
  navigationBar: {
    withBackButton: true,
    withHomeButton: false,
    withTitle: true,
    theme: 'light',
  },
  webView: {
    bounces: false,
    pullToRefreshEnabled: false,
    overScrollMode: 'never',
  },
  webBundleDir: 'dist',
});
