// One app's popups, Mac-style. Collapsed: the newest card on top with up to
// two cards peeking out underneath and a count. Clicking a collapsed stack
// expands it into the full list; each card then has its own close button.
// Pure presentational: the service owns the rows, timers and expanded state.

import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property string app: ""
  property int count: 1
  property bool expanded: false
  // The stack's popup rows, newest first. Each carries `name` (its file name),
  // which is how the service finds the row again.
  property var members: []
  property int cornerRadius: 0
  property string fontFamily: ""
  // Tallest the expanded list may grow before it scrolls.
  property real maxHeight: 100000

  readonly property bool hovered: hover.hovered
  readonly property var head: members.length > 0 ? members[0] : ({})
  readonly property bool stacked: count > 1
  readonly property int peekCount: expanded ? 0 : Math.min(2, Math.max(0, count - 1))
  readonly property real peekStep: Style.space(6)
  readonly property real peekInset: Style.space(10)
  readonly property color peekColor: Qt.darker(Commons.Color.notifications.background, 1.3)

  signal expandRequested()
  signal collapseRequested()
  signal clearRequested()
  signal cardClicked(string name)
  signal cardClosed(string name)

  implicitWidth: Style.space(380)
  implicitHeight: expanded
    ? expandedColumn.implicitHeight
    : headCard.implicitHeight + peekCount * peekStep

  HoverHandler { id: hover }

  // ------------------------------------------------------------ collapsed

  Item {
    anchors.fill: parent
    visible: !root.expanded

    // The cards underneath. Only their bottom edge shows; the rest is hidden
    // behind the card in front.
    Repeater {
      model: root.peekCount
      delegate: Rectangle {
        required property int index
        readonly property int depth: root.peekCount - index
        z: -depth
        x: root.peekInset * depth
        width: root.width - 2 * root.peekInset * depth
        height: Math.max(root.cornerRadius, Style.space(4)) + root.peekStep
        y: headCard.height + root.peekStep * depth - height
        radius: root.cornerRadius
        color: root.peekColor
        border.color: Commons.Color.notifications.border
        border.width: Math.max(1, Style.space(1))
      }
    }

    NotificationCard {
      id: headCard
      width: parent.width
      app: root.head.app || ""
      appIcon: root.head.appIcon || ""
      summary: root.head.summary || ""
      body: root.head.body || ""
      image: root.head.image || ""
      glyph: root.head.glyph || ""
      urgency: root.head.urgency === undefined ? 1 : root.head.urgency
      timestamp: root.head.timestamp || 0
      cornerRadius: root.cornerRadius
      fontFamily: root.fontFamily
      stackCount: root.count

      // On a stack, a click opens it and the close button clears it, the
      // way a collapsed macOS group behaves. A lone card acts on itself.
      onCardClicked: root.stacked ? root.expandRequested() : root.cardClicked(root.head.name)
      onCloseRequested: root.stacked ? root.clearRequested() : root.cardClosed(root.head.name)
    }
  }

  // ------------------------------------------------------------- expanded

  ColumnLayout {
    id: expandedColumn
    visible: root.expanded
    width: parent.width
    spacing: Style.space(6)

    Rectangle {
      id: header
      Layout.fillWidth: true
      implicitHeight: headerRow.implicitHeight + Style.space(12)
      radius: root.cornerRadius
      color: Commons.Color.notifications.background
      border.color: Commons.Color.notifications.border
      border.width: Math.max(1, Style.space(2))

      RowLayout {
        id: headerRow
        anchors.fill: parent
        anchors.leftMargin: Style.space(12)
        anchors.rightMargin: Style.space(6)
        spacing: Style.space(6)

        Text {
          Layout.fillWidth: true
          textFormat: Text.PlainText
          text: root.app + "  ·  " + root.count
          elide: Text.ElideRight
          color: Commons.Color.notifications.text
          font.family: "Liberation Sans"
          font.pixelSize: Style.font.title
          font.bold: true
        }

        HeaderButton {
          label: "Show less"
          onClicked: root.collapseRequested()
        }

        HeaderButton {
          label: "Clear all"
          onClicked: root.clearRequested()
        }
      }
    }

    // Scrolls once the list is taller than the screen allows.
    Flickable {
      id: flick
      Layout.fillWidth: true
      Layout.preferredHeight: Math.min(cards.implicitHeight, Math.max(Style.space(80), root.maxHeight - header.height - expandedColumn.spacing))
      contentWidth: width
      contentHeight: cards.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: cards
        width: flick.width
        spacing: Style.space(6)

        Repeater {
          model: root.expanded ? root.members : []
          delegate: NotificationCard {
            required property var modelData
            width: cards.width
            app: modelData.app || ""
            appIcon: modelData.appIcon || ""
            summary: modelData.summary || ""
            body: modelData.body || ""
            image: modelData.image || ""
            glyph: modelData.glyph || ""
            urgency: modelData.urgency === undefined ? 1 : modelData.urgency
            timestamp: modelData.timestamp || 0
            cornerRadius: root.cornerRadius
            fontFamily: root.fontFamily

            onCardClicked: root.cardClicked(modelData.name)
            onCloseRequested: root.cardClosed(modelData.name)
          }
        }
      }
    }
  }

  component HeaderButton: Rectangle {
    id: button
    property string label: ""
    signal clicked()

    implicitHeight: buttonLabel.implicitHeight + Style.space(8)
    implicitWidth: buttonLabel.implicitWidth + Style.space(16)
    radius: height / 2
    color: buttonArea.containsMouse ? Commons.Color.notifications.text : "transparent"
    border.color: Commons.Color.notifications.border
    border.width: Math.max(1, Style.space(1))

    Text {
      id: buttonLabel
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: button.label
      color: buttonArea.containsMouse ? Commons.Color.notifications.background : Commons.Color.notifications.text
      font.family: "Liberation Sans"
      font.pixelSize: Style.font.bodySmall
    }

    MouseArea {
      id: buttonArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }
}
