//
//  BalanceStatusView.swift
//  Edmund
//
//  Created by Hollan Sellars on 6/4/25.
//

import SwiftUI

struct BalanceStatusText : View {
    let data: Decimal;
    var reverse: Bool = false;
    
    var overText: LocalizedStringKey {
        reverse ? "Under" : "Over"
    }
    var underText: LocalizedStringKey {
        reverse ? "Over" : "Under"
    }
    
    var body: some View {
        Text(data == 0 ? "Balanced" : data > 0 ? overText : underText)
    }
}

#Preview {
    BalanceStatusText(data: 400)
}
