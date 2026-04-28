package corman.air.pulse.airpulse;

import android.content.Context;
import android.os.Bundle;
import com.ryanheise.audioservice.AudioServiceActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends AudioServiceActivity {
    private static final String VOLUME_CHANNEL = "com.airpulse/volume";
    private VolumeListener volumeListener;
    private MethodChannel volumeChannel;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        volumeChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), VOLUME_CHANNEL);
        volumeChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "startVolumeListener":
                    startVolumeListener();
                    result.success(null);
                    break;
                case "stopVolumeListener":
                    stopVolumeListener();
                    result.success(null);
                    break;
                case "setVolume":
                    Double volume = call.argument("volume");
                    if (volume != null && volumeListener != null) {
                        volumeListener.setVolume(volume.floatValue());
                    }
                    result.success(null);
                    break;
                default:
                    result.notImplemented();
            }
        });
    }

    private void startVolumeListener() {
        if (volumeListener == null) {
            volumeListener = new VolumeListener(this, volume -> {
                if (volumeChannel != null) {
                    volumeChannel.invokeMethod("onVolumeChanged", 
                        java.util.Collections.singletonMap("volume", (double) volume));
                }
            });
            volumeListener.startListening();
        }
    }

    private void stopVolumeListener() {
        if (volumeListener != null) {
            volumeListener.stopListening();
            volumeListener = null;
        }
    }

    @Override
    protected void onDestroy() {
        stopVolumeListener();
        super.onDestroy();
    }
}

