import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


class AndroidWidgetResourcesTest(unittest.TestCase):
    def test_all_remote_views_layouts_use_supported_view_classes_and_common_ids(self):
        supported = {
            "FrameLayout",
            "LinearLayout",
            "RelativeLayout",
            "TextView",
            "ImageView",
            "Space",
        }
        required_ids = {
            "@+id/widget_root",
            "@+id/widget_seal",
            "@+id/widget_verse_text",
            "@+id/widget_reference",
            "@+id/widget_edition",
        }
        for name in ("widget_compact.xml", "widget_medium.xml", "widget_large.xml"):
            root = ET.parse(
                ROOT / "android/app/src/main/res/layout" / name
            ).getroot()
            tags = {node.tag.split("}")[-1].split(".")[-1] for node in root.iter()}
            self.assertTrue(tags <= supported, (name, tags - supported))
            ids = {node.attrib.get(ANDROID + "id") for node in root.iter()}
            self.assertTrue(required_ids <= ids, (name, required_ids - ids))

    def test_provider_declares_home_keyguard_and_hourly_refresh(self):
        root = ET.parse(
            ROOT / "android/app/src/main/res/xml/widget_info.xml"
        ).getroot()
        self.assertEqual(root.attrib[ANDROID + "widgetCategory"], "home_screen|keyguard")
        self.assertEqual(root.attrib[ANDROID + "updatePeriodMillis"], "3600000")
        self.assertEqual(root.attrib[ANDROID + "initialLayout"], "@layout/widget_medium")
        self.assertEqual(
            root.attrib[ANDROID + "initialKeyguardLayout"],
            "@layout/widget_compact",
        )


if __name__ == "__main__":
    unittest.main()
