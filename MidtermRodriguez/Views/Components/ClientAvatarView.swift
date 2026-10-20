//
//  ClientAvatarView.swift
//  InvoiceManager
//
//  Reusable component: a client's initials in a coloured circle.
//  Each client keeps the same colour everywhere in the app, which makes
//  them easy to spot in long lists.
//

import SwiftUI

struct ClientAvatarView: View {

    let client: Client
    var size: CGFloat = 40

    var body: some View {
        Text(client.initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.avatarColor(for: client.id), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(SampleData.clients) { client in
            ClientAvatarView(client: client)
        }
    }
    .padding()
}
