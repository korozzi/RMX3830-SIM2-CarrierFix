package com.rmx3830.imeidiagnostics;

import android.os.Build;
import android.telephony.TelephonyManager;
import java.lang.reflect.Method;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import io.github.libxposed.api.XposedModule;
import io.github.libxposed.api.XposedModuleInterface;

public final class ImeiDiagnosticsModule extends XposedModule {
    private static final String TAG = "RMX3830ImeiDiag";
    private static final Set<String> HOOKED = new HashSet<>();

    @Override public void onModuleLoaded(XposedModuleInterface.ModuleLoadedParam p) {
        note("LOADED process=" + p.getProcessName() + " systemServer=" + p.isSystemServer()
                + " sdk=" + Build.VERSION.SDK_INT + " api=" + getApiVersion());
    }

    @Override public void onSystemServerStarting(XposedModuleInterface.SystemServerStartingParam p) {
        note("SYSTEM_SERVER_START");
        scanAndHook(p.getClassLoader(), new String[]{
                "com.android.server.TelephonyRegistry",
                "com.android.server.telephony.TelephonyShellCommand",
                "com.android.phone.PhoneInterfaceManager",
                "com.android.internal.telephony.PhoneSubInfoController"
        });
    }

    @Override public void onPackageReady(XposedModuleInterface.PackageReadyParam p) {
        String pkg = p.getPackageName();
        if (!"android".equals(pkg) && !"com.android.phone".equals(pkg)) return;
        note("PACKAGE_READY " + pkg);
        hookMethod(TelephonyManager.class, "getImei");
        hookMethod(TelephonyManager.class, "getImei", int.class);
        hookMethod(TelephonyManager.class, "getDeviceId");
        hookMethod(TelephonyManager.class, "getDeviceId", int.class);
        scanAndHook(p.getClassLoader(), new String[]{
                "com.android.internal.telephony.Phone",
                "com.android.internal.telephony.GsmCdmaPhone",
                "com.android.internal.telephony.PhoneSubInfo",
                "com.android.internal.telephony.PhoneSubInfoController",
                "com.android.internal.telephony.RIL",
                "com.android.phone.PhoneInterfaceManager"
        });
    }

    private void scanAndHook(ClassLoader cl, String[] classes) {
        for (String name : classes) {
            try {
                Class<?> c = Class.forName(name, false, cl);
                note("CLASS " + name);
                for (Method m : c.getDeclaredMethods()) {
                    String n = m.getName().toLowerCase(Locale.ROOT);
                    if (n.contains("imei") || n.equals("getdeviceid") || n.contains("deviceid")) {
                        note("CANDIDATE " + m.toGenericString());
                        hookMethod(m);
                    }
                }
            } catch (Throwable t) {
                note("CLASS_MISS " + name + " " + t.getClass().getSimpleName());
            }
        }
    }

    private void hookMethod(Class<?> owner, String name, Class<?>... args) {
        try { hookMethod(owner.getDeclaredMethod(name, args)); } catch (Throwable ignored) { }
    }

    private void hookMethod(Method m) {
        String key = m.toGenericString();
        if (!HOOKED.add(key)) return;
        try {
            hook(m).intercept(chain -> {
                Object result = chain.proceed();
                note("CALL " + key + " -> " + describe(result));
                return result;
            });
            note("HOOKED " + key);
        } catch (Throwable t) {
            note("HOOK_FAILED " + key + " " + t.getClass().getSimpleName());
        }
    }

    private static String describe(Object value) {
        if (value == null) return "<null>";
        String s = String.valueOf(value);
        if (s.isEmpty()) return "<empty>";
        if (s.matches("\\d{14,16}")) {
            return "<numeric,len=" + s.length() + ",last4=" + s.substring(s.length()-4) + ">";
        }
        return "<" + value.getClass().getSimpleName() + ",len=" + s.length() + ">";
    }

    private void note(String msg) {
        try { log(INFO, TAG, msg); } catch (Throwable ignored) { }
    }
}
