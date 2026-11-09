# LifeLink free notification hosting

This Worker replaces the old PHP notification server. Deploy it for free to
Cloudflare Workers; no `web/` dashboard folder, PHP host, Composer, or domain
is required for testing.

## Dashboard deployment

1. Create a free Cloudflare account at https://dash.cloudflare.com/sign-up.
2. Open **Workers & Pages** -> **Create application** -> **Create Worker**.
   Name it `lifelink-notify`, then click **Deploy**.
3. Open the new Worker -> **Edit code**. Replace its code with the contents of
   `src/index.js` in this folder. Click **Deploy**.
4. Open **Settings** -> **Variables and Secrets** -> **Add**. Add:

   | Name | Type | Value |
   | --- | --- | --- |
   | `FIREBASE_PROJECT_ID` | Text | `lifelink-66e5b` |
   | `FIREBASE_WEB_API_KEY` | Secret | Firebase Console Web API Key |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | Secret | Entire contents of the downloaded service-account JSON file |

   Click **Deploy** after adding the variables.
5. Copy the Worker URL, for example:

   ```text
   https://lifelink-notify.YOUR_SUBDOMAIN.workers.dev
   ```

6. Deploy Firestore rules from the Flutter project:

   ```powershell
   firebase deploy --only firestore:rules
   ```

7. Run Flutter using that exact URL:

   ```powershell
   flutter run --dart-define=LIFELINK_NOTIFICATION_WORKER_URL=https://lifelink-notify.YOUR_SUBDOMAIN.workers.dev
   ```

## Security

The Worker keeps the Firebase service-account JSON encrypted as a Cloudflare
secret. It verifies the Firebase login token and confirms that both accounts
are members of the chat before sending FCM. Never put the service-account JSON
inside Flutter, Firestore, Git, or a public web folder.
