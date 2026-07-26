package io.github.junkerderprovinz;

import java.lang.instrument.ClassFileTransformer;
import java.lang.instrument.Instrumentation;
import java.security.ProtectionDomain;

import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.Label;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

/**
 * Standalone -javaagent that fixes JDownloader's Event Scripter script editor when the FlatLaf
 * dark Look-and-Feel is active (e.g. the "JD Plain Dark" theme, or JD's own flatlaf-themes dark).
 *
 * Two latent NullPointerExceptions in JDownloader's bundled code only fire under FlatLaf and are
 * swallowed silently, so the script editor dialog aborts before it maps and "edit"/"Add script"
 * does nothing:
 *   1. org.appwork.swing.components.circlebar.BasicCircleProgressBarUI derefs a null circleBar
 *      field during layout (getPreferredSize/paint/update) when FlatLaf re-realizes the transient
 *      progress-circle rubber-stamp widget.
 *   2. jsyntaxpane.actions.ScriptAction derefs its static ScriptEngine `engine` (null: no
 *      javax.script JavaScript engine since Nashorn was removed in Java 15) while installing the
 *      code-editor kit.
 *
 * This agent guards both at the root with a load-time bytecode transform. Nothing else is touched;
 * it is fail-safe (any transform error, or a future upstream rename, leaves the original bytes
 * unchanged). It has NO effect unless you run one of the affected code paths under FlatLaf.
 *
 * Desktop use: add it to JDownloader's JVM, e.g. set the environment variable
 *   JAVA_TOOL_OPTIONS=-javaagent:/path/to/jd-es-fix.jar
 * before launching JDownloader. See the repository README for details.
 */
public class EventScripterFixAgent {

    private static final String CPB_UI          = "org/appwork/swing/components/circlebar/BasicCircleProgressBarUI";
    private static final String CPB_FIELD_OWNER = "org/appwork/swing/components/circlebar/CircledProgressBar";
    private static final String CPB_FIELD_DESC  = "L" + CPB_FIELD_OWNER + ";";
    private static final String SA_CLASS        = "jsyntaxpane/actions/ScriptAction";
    private static boolean circleBarPatchLogged    = false;
    private static boolean scriptActionPatchLogged = false;

    public static void premain(String agentArgs, Instrumentation inst) {
        try {
            inst.addTransformer(new ClassFileTransformer() {
                @Override
                public byte[] transform(ClassLoader loader, String className, Class<?> classBeingRedefined,
                                        ProtectionDomain pd, byte[] classfileBuffer) {
                    try {
                        if (CPB_UI.equals(className))  return patchCircleBarUI(classfileBuffer, loader);
                        if (SA_CLASS.equals(className)) return patchScriptAction(classfileBuffer, loader);
                        return null;
                    } catch (Throwable err) {
                        System.out.println("[jd-es-fix] transform skipped for " + className + " (" + err + ")");
                        return null;   // fail-safe: original bytes, no regression
                    }
                }
            }, true);
            System.out.println("[jd-es-fix] Event Scripter FlatLaf fix armed"
                    + " (CircledProgressBar + jsyntaxpane ScriptAction null-guards)");
        } catch (Throwable err) {
            System.out.println("[jd-es-fix] could not arm (" + err + ")");
        }
    }

    /** Rebind circleBar from the passed component / null-guard getPreferredSize + paint + update. */
    private static byte[] patchCircleBarUI(byte[] original, final ClassLoader loader) {
        ClassReader cr = new ClassReader(original);
        ClassWriter cw = new ClassWriter(cr, ClassWriter.COMPUTE_FRAMES) {
            @Override
            protected ClassLoader getClassLoader() {
                return loader != null ? loader : super.getClassLoader();
            }
        };
        final int[] patchedCount = { 0 };
        ClassVisitor cv = new ClassVisitor(Opcodes.ASM9, cw) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] ex) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, ex);
                final int cIdx;
                final boolean isVoid;
                if ("getPreferredSize".equals(name) && "(Ljavax/swing/JComponent;)Ljava/awt/Dimension;".equals(desc)) {
                    cIdx = 1; isVoid = false;
                } else if (("paint".equals(name) || "update".equals(name))
                        && "(Ljava/awt/Graphics;Ljavax/swing/JComponent;)V".equals(desc)) {
                    cIdx = 2; isVoid = true;
                } else {
                    return mv;
                }
                patchedCount[0]++;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override
                    public void visitCode() {
                        super.visitCode();
                        Label afterRebind = new Label();
                        visitVarInsn(Opcodes.ALOAD, 0);
                        visitFieldInsn(Opcodes.GETFIELD, CPB_UI, "circleBar", CPB_FIELD_DESC);
                        visitJumpInsn(Opcodes.IFNONNULL, afterRebind);
                        visitVarInsn(Opcodes.ALOAD, cIdx);
                        visitTypeInsn(Opcodes.INSTANCEOF, CPB_FIELD_OWNER);
                        visitJumpInsn(Opcodes.IFEQ, afterRebind);
                        visitVarInsn(Opcodes.ALOAD, 0);
                        visitVarInsn(Opcodes.ALOAD, cIdx);
                        visitTypeInsn(Opcodes.CHECKCAST, CPB_FIELD_OWNER);
                        visitFieldInsn(Opcodes.PUTFIELD, CPB_UI, "circleBar", CPB_FIELD_DESC);
                        visitLabel(afterRebind);
                        Label proceed = new Label();
                        visitVarInsn(Opcodes.ALOAD, 0);
                        visitFieldInsn(Opcodes.GETFIELD, CPB_UI, "circleBar", CPB_FIELD_DESC);
                        visitJumpInsn(Opcodes.IFNONNULL, proceed);
                        if (isVoid) {
                            visitInsn(Opcodes.RETURN);
                        } else {
                            visitTypeInsn(Opcodes.NEW, "java/awt/Dimension");
                            visitInsn(Opcodes.DUP);
                            visitInsn(Opcodes.ICONST_0);
                            visitInsn(Opcodes.ICONST_0);
                            visitMethodInsn(Opcodes.INVOKESPECIAL, "java/awt/Dimension", "<init>", "(II)V", false);
                            visitInsn(Opcodes.ARETURN);
                        }
                        visitLabel(proceed);
                    }
                };
            }
        };
        cr.accept(cv, 0);
        if (patchedCount[0] == 0) return null;
        if (!circleBarPatchLogged) { circleBarPatchLogged = true;
            System.out.println("[jd-es-fix] patched BasicCircleProgressBarUI (circleBar null-guard)"); }
        return cw.toByteArray();
    }

    /** No-op ScriptAction.install()/getScriptFromURL() when the static ScriptEngine is null. */
    private static byte[] patchScriptAction(byte[] original, final ClassLoader loader) {
        ClassReader cr = new ClassReader(original);
        ClassWriter cw = new ClassWriter(cr, ClassWriter.COMPUTE_FRAMES) {
            @Override
            protected ClassLoader getClassLoader() {
                return loader != null ? loader : super.getClassLoader();
            }
        };
        final int[] patchedCount = { 0 };
        ClassVisitor cv = new ClassVisitor(Opcodes.ASM9, cw) {
            @Override
            public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] ex) {
                MethodVisitor mv = super.visitMethod(access, name, desc, sig, ex);
                boolean guard =
                       ("install".equals(name)
                          && "(Ljavax/swing/JEditorPane;Ljsyntaxpane/util/Configuration;Ljava/lang/String;)V".equals(desc))
                    || ("getScriptFromURL".equals(name) && "(Ljava/lang/String;)V".equals(desc));
                if (!guard) return mv;
                patchedCount[0]++;
                return new MethodVisitor(Opcodes.ASM9, mv) {
                    @Override
                    public void visitCode() {
                        super.visitCode();
                        Label proceed = new Label();
                        visitFieldInsn(Opcodes.GETSTATIC, SA_CLASS, "engine", "Ljavax/script/ScriptEngine;");
                        visitJumpInsn(Opcodes.IFNONNULL, proceed);
                        visitInsn(Opcodes.RETURN);
                        visitLabel(proceed);
                    }
                };
            }
        };
        cr.accept(cv, 0);
        if (patchedCount[0] == 0) return null;
        if (!scriptActionPatchLogged) { scriptActionPatchLogged = true;
            System.out.println("[jd-es-fix] patched jsyntaxpane ScriptAction (null-engine guard)"); }
        return cw.toByteArray();
    }
}
