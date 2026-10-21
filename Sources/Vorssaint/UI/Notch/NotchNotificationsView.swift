// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import AppKit
import SwiftUI

struct NotchNotificationsView: View {
    let size: CGSize
    @ObservedObject private var service = NotchNotificationService.shared
    @ObservedObject private var permissions = Permissions.shared
    @ObservedObject private var l10n = L10n.shared
    private var text: NotchNotificationStrings { FeatureStrings.notchNotifications(l10n.language) }

    var body: some View {
        Group {
            if !permissions.accessibility {
                VStack(alignment: .leading, spacing: 10) {
                    PermissionRow(kind: .accessibility)
                    Text(text.privacy).font(.callout).foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if service.items.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "bell").font(.system(size: 26, weight: .light)).foregroundStyle(.white.opacity(0.6))
                        .frame(width: 56, height: 56)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.monitoring ? text.empty : text.waiting).font(.headline)
                        Text(text.privacy).font(.caption).foregroundStyle(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let rows = NotchLayout.railRows(count: service.items.count,
                                                perRow: NotchLayout.railCapacity(width: size.width, itemWidth: NotchLayout.listCardWidth, spacing: 8), // mog: share the container's column width.
                                                rowHeight: 120, spacing: 8, height: size.height)
                let cardHeight = (size.height - CGFloat(rows - 1) * 8) / CGFloat(rows)
                NotchRail(items: service.items, rows: rows, itemWidth: NotchLayout.listCardWidth, width: size.width) { item in // mog:
                    NotchNotificationRow(item: item, service: service, text: text)
                        .frame(height: cardHeight)
                }
                .notchScrollEdgeFade() // mog: hide scrollers and hint at overflow.
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.locale, l10n.language.formattingLocale())
    }
}

/// The page shows only the cards, so clearing sits in the island's header
/// like the captures page's. Observes the inbox on its own, so a new message
/// does not redraw the island.
struct NotchClearNotificationsButton: View {
    @ObservedObject private var notifications = NotchNotificationService.shared
    @ObservedObject private var l10n = L10n.shared

    var body: some View {
        NotchIconButton(symbol: "trash", title: FeatureStrings.notchNotifications(l10n.language).clearAll,
                        action: Self.confirmClearAboveIsland)
            .disabled(notifications.items.isEmpty || notifications.openingID != nil)
    }

    /// With the system banner dismissed, a banner shown while the island was
    /// closed may never reach Notification Center before macOS 27, so the
    /// island can hold the only copy. Clearing asks first, above the island.
    static func confirmClearAboveIsland() {
        DispatchQueue.main.async {
            let l10n = L10n.shared
            let title = FeatureStrings.notchNotifications(l10n.language).clearAll
            guard NSAlert.confirmAboveIsland(title, message: "", action: title, destructive: true,
                                             cancel: l10n.s.uninstallerCancel) else { return }
            NotchNotificationService.shared.clearAll()
        }
    }
}

// mog: the card is the primary action; the dismiss control is a sibling, never a nested button.
private struct NotchNotificationRow: View {
    let item: NotchSystemNotification
    @ObservedObject var service: NotchNotificationService
    let text: NotchNotificationStrings
    @State private var hovered = false

    var body: some View {
        Button {
            service.open(item.id) { result in
                if result == .handedOff || result == .openedApplication { NotchService.shared.collapse() }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    NotchNotificationAppIcon(app: item.content.app, size: 22)
                    Text(item.content.app.isEmpty ? text.title : item.content.app).lineLimit(1)
                    Spacer(minLength: 4)
                    Text(item.received, format: .dateTime.hour().minute()).monospacedDigit()
                    if service.openingID == item.id { ProgressView().controlSize(.mini) }
                    Color.clear.frame(width: 22, height: 22)
                }
                .font(.system(size: 11)).foregroundStyle(.white.opacity(0.55))
                Text(item.content.compactTitle).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                if !item.content.compactDetail.isEmpty {
                    Text(item.content.compactDetail).font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
                if service.unavailableID == item.id {
                    Text(text.unavailable).font(.caption).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(NotchButtonStyle(cornerRadius: 14, lifts: false))
        .disabled(service.openingID != nil)
        .accessibilityLabel(item.content.accessibilityText)
        .accessibilityHint(text.open)
        .overlay(alignment: .topTrailing) {
            NotchIconButton(symbol: "xmark", title: text.dismiss) { service.dismiss(item.id) }
                .disabled(service.openingID == item.id)
                .opacity(hovered ? 1 : 0)
                .padding(12)
        }
        .onHover { hovered = $0 }
    }
}

// mog: arrivals and held banners share the same directly clickable, two-line preview.
struct NotchNotificationPreviewView: View {
    let notice: NotchNotice
    let content: NotchNotificationContent
    @ObservedObject var service: NotchService
    @ObservedObject private var notifications = NotchNotificationService.shared
    @ObservedObject private var l10n = L10n.shared
    @State private var hovered = false
    private var text: NotchNotificationStrings { FeatureStrings.notchNotifications(l10n.language) }
    private var item: NotchSystemNotification? {
        notifications.items.first { $0.id == notice.notificationID }
    }

    var body: some View {
        Button { service.activateNotice(notice) } label: {
            VStack(alignment: .leading, spacing: NotchNotificationPreviewLayout.spacing) {
                HStack(spacing: 8) {
                    NotchNotificationAppIcon(app: content.app, size: NotchNotificationPreviewLayout.iconSize)
                    Text(content.app.isEmpty ? text.title : content.app)
                        .font(.system(size: 12, weight: .semibold)).lineLimit(1)
                    Spacer(minLength: 8)
                    if let item {
                        Text(item.received, format: .dateTime.hour().minute())
                            .font(.system(size: 11)).monospacedDigit()
                    }
                    if notifications.openingID == notice.notificationID { ProgressView().controlSize(.mini) }
                    Color.clear.frame(width: 22, height: 22)
                }
                .foregroundStyle(.white.opacity(0.55))
                .frame(height: NotchNotificationPreviewLayout.headerHeight)
                if !content.title.isEmpty {
                    Text(content.title)
                        .font(Font(NotchNotificationPreviewLayout.titleFont as CTFont))
                        .lineLimit(NotchNotificationPreviewLayout.titleLines)
                }
                if !content.subtitle.isEmpty {
                    Text(content.subtitle)
                        .font(Font(NotchNotificationPreviewLayout.subtitleFont as CTFont))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(NotchNotificationPreviewLayout.subtitleLines)
                }
                if !content.body.isEmpty {
                    Text(content.body)
                        .font(Font(NotchNotificationPreviewLayout.bodyFont as CTFont))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(NotchNotificationPreviewLayout.bodyLines)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(.black)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(NotchButtonStyle(cornerRadius: 14, lifts: false))
        .disabled(notifications.openingID != nil)
        .accessibilityLabel(notice.accessibilityText)
        .accessibilityHint(text.open)
        .overlay(alignment: .topTrailing) {
            NotchIconButton(symbol: "xmark", title: text.dismiss) { service.dismissNotification(notice) }
                .disabled(notifications.openingID == notice.notificationID)
                .opacity(hovered ? 1 : 0)
        }
        .onHover { hovered = $0 }
        .environment(\.locale, l10n.language.formattingLocale())
    }
}

struct NotchNotificationAppIcon: View {
    let app: String
    let size: CGFloat
    @ObservedObject private var service = NotchNotificationService.shared

    var body: some View {
        Group {
            if let icon = service.icon(for: app) {
                Image(nsImage: icon).resizable().scaledToFit()
            } else {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: size * 0.48, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: size, height: size)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: size * 0.24))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
