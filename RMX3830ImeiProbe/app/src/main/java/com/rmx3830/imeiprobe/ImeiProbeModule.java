package com.rmx3830.imeiprobe;

import android.telephony.TelephonyManager;
import android.util.Log;
import java.lang.reflect.Method;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface;

public final class ImeiProbeModule extends XposedModule {
    private static final String TAG = "RMX3830ImeiProbe";
    private static final String PHONE = "com.android.phone";
    private static final String ANDROID = "android";

    @Override
    public void onModuleLoaded(XposedModuleInterface.ModuleLoadedParam param) {
        log(Log.INFO, TAG, "loaded process=" + param.getProcessName()
                + " systemServer=" + param.isSystemServer()
                + " api=" + getApiVersion());
    }

    @Override
    public void onPackageReady(XposedModuleInterface.PackageReadyParam param) {
        final String pkg = param.getPackageName();
        if (!ANDROID.equals(pkg) && !PHONE.equals(pkg)) return;
        log(Log.INFO, TAG, "target ready package=" + pkg);
        installHooks(param.getClassLoader(), pkg);
    }

    @Override
    public void onSystemServerStarting(XposedModuleInterface.SystemServerStartingParam param) {
        log(Log.INFO, TAG, "system_server starting");
    }

    private void installHooks(ClassLoader cl, String pkg) {
        tryHook(TelephonyManager.class, "getImei");
        tryHook(TelephonyManager.class, "getImei", int.class);
        tryHook(TelephonyManager.class, "getDeviceId");
        tryHook(TelephonyManager.class, "getDeviceId", int.class);

        String[] candidates = {
                "com.android.internal.telephony.Phone",
                "com.android.internal.telephony.PhoneBase",
                "com.android.internal.telephony.PhoneSubInfoController",
                "com.android.internal.telephony.PhoneSubInfo",
                "com.android.internal.telephony.RIL"
        };
        for (String name : candidates) {
            try {
                Class<?> c = Class.forName(name, false, cl);
                for (Method m : c.getDeclaredMethods()) {
                    String n = m.getName().toLowerCase();
                    if (n.contains("imei") || n.equals("getdeviceid") || n.contains("deviceid")) {
                        tryHookMethod(m);
                    }
                }
            } catch (Throwable ignored) {}
        }
        log(Log.INFO, TAG, "hooks installed for " + pkg);
    }

    private void tryHook(Class<?> owner, String name, Class<?>... args) {
        try {
            tryHookMethod(owner.getDeclaredMethod(name, args));
        } catch (Throwable ignored) {}
    }

    private void tryHookMethod(Method method) {
        try {
            hook(method).intercept(chain -> {
                Object result = chain.proceed();
                String value = result == null ? "<null>" : String.valueOf(result);
                log(Log.INFO, TAG, "CALL " + method.getDeclaringClass().getName()
                        + "." + method.getName() + " -> " + mask(value));
                return result;
            });
        } catch (Throwable t) {
            log(Log.WARN, TAG, "hook failed " + method, t);
        }
    }

    private static String mask(String s) {
        if (s == null) return "<null>";
        if (s.length() <= 4) return "<len=" + s.length() + ">";
        return "<masked,len=" + s.length() + ",last4=" + s.substring(s.length() - 4) + ">";
    }
}
