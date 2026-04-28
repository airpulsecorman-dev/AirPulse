package corman.air.pulse.airpulse;

import android.content.Context;
import android.media.AudioManager;
import android.os.Handler;
import android.os.Looper;

public class VolumeListener {
    private final Context context;
    private final VolumeChangeCallback callback;
    private final AudioManager audioManager;
    private final Handler handler;
    private float lastVolume;
    private final int maxVolume;
    private Runnable pollingRunnable;
    private boolean isManuallyChanging = false;
    private static final long MANUAL_CHANGE_DELAY_MS = 500;

    public interface VolumeChangeCallback {
        void onVolumeChanged(float volume);
    }

    public VolumeListener(Context context, VolumeChangeCallback callback) {
        this.context = context;
        this.callback = callback;
        this.audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        this.handler = new Handler(Looper.getMainLooper());
        this.maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        this.lastVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC) / (float) Math.max(1, maxVolume);
    }

    public void startListening() {
        pollingRunnable = new Runnable() {
            @Override
            public void run() {
                // No procesar cambios si estamos en una operación manual
                if (isManuallyChanging) {
                    handler.postDelayed(this, 100);
                    return;
                }

                int currentVol = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
                float normalizedVolume = currentVol / (float) Math.max(1, maxVolume);

                if (Math.abs(normalizedVolume - lastVolume) > 0.02f) {
                    lastVolume = normalizedVolume;
                    callback.onVolumeChanged(normalizedVolume);
                }

                handler.postDelayed(this, 100);
            }
        };
        handler.post(pollingRunnable);
    }

    public void stopListening() {
        if (pollingRunnable != null) {
            handler.removeCallbacks(pollingRunnable);
        }
    }

    public void setVolume(float volume) {
        int streamVolume = (int) (volume * maxVolume);
        
        // Flag para evitar que el listener interfiera
        isManuallyChanging = true;
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, streamVolume, 0);
        lastVolume = volume;
        
        // Esperar a que se estabilice el cambio antes de permitir que el listener actúe
        handler.removeCallbacks(null);
        handler.postDelayed(() -> isManuallyChanging = false, MANUAL_CHANGE_DELAY_MS);
    }
}
