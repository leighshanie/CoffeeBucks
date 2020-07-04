//
//  ContentView.swift
//  Shared
//
//  Created by Shane Leigh on 04/07/2020.
//

//import Combine
import SwiftUI

class Order: ObservableObject, Codable {
    enum CodingKeys: CodingKey {
        case type
        case quantity
        case extraSugar
        case extraMilk
        case name
        case address
        case phoneNumber
        case city
        case postCode
    }
    
//    var didChange = PassthroughSubject<Void, Never>()
    
    static let types = ["Cappuccino", "Latte", "Americano", "Espresso", "Hot Chocolate"]

    @Published var type = 0
    @Published var quantity = 1
    
    @Published var specialRequestEnabled = false
    @Published var extraSugar = false
    @Published var extraMilk = false

    @Published var name = ""
    @Published var address = ""
    @Published var phoneNumber = ""
    @Published var city = ""
    @Published var postCode = ""
    
    var isValid: Bool {
        if name.isEmpty || address.isEmpty || phoneNumber.isEmpty || city.isEmpty || postCode.isEmpty {
            return false
        }
        return true
    }
    
    // magic
    init() {}
    
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(Int.self, forKey: .type)
        quantity = try container.decode(Int.self, forKey: .quantity)
        extraSugar = try container.decode(Bool.self, forKey: .extraSugar)
        extraMilk = try container.decode(Bool.self, forKey: .extraMilk)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        city = try container.decode(String.self, forKey: .city)
        postCode = try container.decode(String.self, forKey: .postCode)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(extraSugar, forKey: .extraSugar)
        try container.encode(extraMilk, forKey: .extraMilk)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encode(city, forKey: .city)
        try container.encode(postCode, forKey: .postCode)

    }
    
    
//    func update() {
//        didChange.send(())
//    }
}

struct ContentView: View {
    @ObservedObject var order = Order()
    
    @State var confirmationMessage = ""
    @State var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(selection: $order.type, label: Text("Select your coffee type")) {
                        ForEach(0 ..< Order.types.count) {
                            Text(Order.types[$0]).tag($0)
                        }
                    }
                    
                    Stepper(value: $order.quantity, in: 1...20) {
                        Text("Number of coffee: \(order.quantity)")
                    }
                }
                
                Section {
                    Toggle(isOn: $order.specialRequestEnabled) {
                        Text("Any special requests")
                    }
                    
                    if order.specialRequestEnabled {
                        Toggle(isOn: $order.extraSugar) {
                            Text("Add extra sugar")
                        }
                        
                        Toggle(isOn: $order.extraMilk) {
                            Text("Add extra milk")
                        }
                    }
                }
                
                Section {
                    TextField("Name", text: $order.name)
                    TextField("phoneNumber", text: $order.phoneNumber)
                    TextField("Address", text: $order.address)
                    TextField("City", text: $order.city)
                    TextField("Post Code", text: $order.postCode)

                }
                
                Section {
                    Button (action: {
                        self.placeOrder()
                    }) {
                        Text("Place order")
                    }.disabled(!order.isValid)
                }
                
            }
            .navigationBarTitle(Text("Coffee Bucks"))
            .alert(isPresented: $showingConfirmation) {
                Alert(title: Text("Thank you!"), message: Text(confirmationMessage), dismissButton: .default(Text("OK")))
            }
            
            
        }
        
    }
    
    func placeOrder() {
        guard  let encoded = try? JSONEncoder().encode(order) else {
            print("Failed to encode order")
            return
        }
        
        
        let url = URL(string: "https://reqres.in/api/coffee")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) {
            guard let data = $0 else {
                print("No data in response: \($2?.localizedDescription ?? "Unknown error").")
                return
            }
            
            if let decodedOrder = try?
                JSONDecoder().decode(Order.self, from: data) {
                self.confirmationMessage = "Your Order for \(decodedOrder.quantity) x \(Order.types[decodedOrder.type].lowercased()) coffee is on its way"
                
                self.showingConfirmation = true
            } else {
                let dataString = String(decoding: data, as: UTF8.self)
                print("Invalid response: \(dataString)")
            }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
