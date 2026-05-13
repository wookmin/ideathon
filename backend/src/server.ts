import { createApp } from './app.js';
import { appEnv } from './config/env.js';

const app = createApp();

app.listen(appEnv.PORT, () => {
  console.log(`TripReceipt CODEF backend listening on port ${appEnv.PORT}`);
});
