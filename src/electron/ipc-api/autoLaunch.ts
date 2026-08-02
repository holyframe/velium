import { app, ipcMain } from 'electron';
import { isWindows } from '../../environment';
import type Settings from '../Settings';

const WINDOWS_LOGIN_ITEM_NAME = 'Velium';
const BACKGROUND_LAUNCH_ARGUMENT = '--launch-in-background';

const getWindowsLoginItemOptions = (openInBackground: boolean) => {
  const path = process.env.PORTABLE_EXECUTABLE_FILE || process.execPath;
  const args: string[] = [];

  if (!app.isPackaged) {
    args.push(app.getAppPath());
  }
  if (openInBackground) {
    args.push(BACKGROUND_LAUNCH_ARGUMENT);
  }

  return { args, path };
};

export default (params: { settings: Settings }) => {
  if (!isWindows) return;

  ipcMain.handle('get-auto-launch', () => {
    const options = getWindowsLoginItemOptions(
      Boolean(params.settings.get('autoLaunchInBackground')),
    );
    const loginItem = app.getLoginItemSettings(options);

    return loginItem.executableWillLaunchAtLogin;
  });

  ipcMain.handle(
    'set-auto-launch',
    (_event, { enable, openInBackground = false }) => {
      const options = getWindowsLoginItemOptions(Boolean(openInBackground));

      app.setLoginItemSettings({
        ...options,
        enabled: Boolean(enable),
        name: WINDOWS_LOGIN_ITEM_NAME,
        openAtLogin: Boolean(enable),
      });

      return app.getLoginItemSettings(options).executableWillLaunchAtLogin;
    },
  );
};
