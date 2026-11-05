// Stats box — volume, microphone, battery and resources share one pill;
// separators hide with the segment before them
import QtQuick
import "../ui"
import "segments"

BarBox {
    id: statsBox

    interactive: true

    VolumeSegment { id: volumeSegment }

    MiniSeparator {
        visible: volumeSegment.visible
    }

    MicSegment { id: micSegment }

    MiniSeparator {
        visible: micSegment.visible
    }

    BatterySegment { id: batterySegment }

    MiniSeparator {
        visible: batterySegment.visible
    }

    ResourcesSegment { id: resourcesSegment }

}
