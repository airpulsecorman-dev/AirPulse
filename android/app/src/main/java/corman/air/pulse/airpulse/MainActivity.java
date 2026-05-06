package corman.air.pulse.airpulse;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Intent;
import android.content.IntentSender;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.MediaStore;
import com.ryanheise.audioservice.AudioServiceActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class MainActivity extends AudioServiceActivity {
    private static final String VOLUME_CHANNEL = "com.airpulse/volume";
    private static final String LIBRARY_CHANNEL = "com.airpulse/library";
    private static final int REQUEST_DELETE = 42;

    private VolumeListener volumeListener;
    private MethodChannel volumeChannel;
    private MethodChannel.Result pendingDeleteResult;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // ── Canal de volumen ──────────────────────────────────────────────────
        volumeChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(), VOLUME_CHANNEL);
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

        // ── Canal de biblioteca (borrado) ─────────────────────────────────────
        MethodChannel libraryChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(), LIBRARY_CHANNEL);
        libraryChannel.setMethodCallHandler((call, result) -> {
            if ("deleteSongs".equals(call.method)) {
                List<String> filePaths = call.argument("filePaths");
                List<String> songIds = call.argument("songIds");
                if (filePaths == null)
                    filePaths = new ArrayList<>();
                if (songIds == null)
                    songIds = new ArrayList<>();
                deleteSongsNative(filePaths, songIds, result);
            } else {
                result.notImplemented();
            }
        });
    }

    private void deleteSongsNative(List<String> filePaths, List<String> songIds,
            MethodChannel.Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            List<Uri> uris = new ArrayList<>();
            ContentResolver resolver = getContentResolver();

            for (int i = 0; i < songIds.size(); i++) {
                try {
                    long id = Long.parseLong(songIds.get(i));
                    uris.add(ContentUris.withAppendedId(
                            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id));
                } catch (NumberFormatException e) {
                    if (i < filePaths.size())
                        deleteByPath(filePaths.get(i));
                }
            }

            if (!uris.isEmpty()) {
                try {
                    IntentSender intentSender = MediaStore.createDeleteRequest(resolver, uris).getIntentSender();
                    pendingDeleteResult = result;
                    startIntentSenderForResult(intentSender, REQUEST_DELETE, null, 0, 0, 0);
                } catch (Exception e) {
                    result.error("DELETE_ERROR", e.getMessage(), null);
                }
            } else {
                result.success(true);
            }
        } else {
            boolean allOk = true;
            for (String path : filePaths)
                allOk &= deleteByPath(path);
            result.success(allOk);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_DELETE && pendingDeleteResult != null) {
            pendingDeleteResult.success(resultCode == Activity.RESULT_OK);
            pendingDeleteResult = null;
        }
    }

    private boolean deleteByPath(String path) {
        if (path == null || path.isEmpty())
            return false;
        try {
            File file = new File(path);
            return !file.exists() || file.delete();
        } catch (Exception e) {
            return false;
        }
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
