import SwiftUI

struct ContentView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var cryptoData: [CryptoData] = []
    @State private var sortingOption: SortingOption = .price // Default sorting option
    
    let refreshInterval: TimeInterval = 2.0
    
    enum SortingOption: String, CaseIterable {
        case price = "💰 Price"
        case percentageChange = "% Change"
    }
    
    var filteredCryptoData: [CryptoData] {
        if searchText.isEmpty {
            return cryptoData
        } else {
            return cryptoData.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var sortedCryptoData: [CryptoData] {
        switch sortingOption {
        case .price:
            return filteredCryptoData.sorted(by: { $0.price > $1.price })
        case .percentageChange:
            return filteredCryptoData.sorted(by: { $0.priceChange24h > $1.priceChange24h })
        }
    }

    @State private var isAddingHolding = false
    @State private var holdings: [PortfolioItem] = [] // Declare holdings at the ContentView level


    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    SearchBar(text: $searchText)
                    
                    Picker(selection: $sortingOption, label: Text("")) {
                        ForEach(SortingOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.leading)
                }
                
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(sortedCryptoData) { data in
                            CryptoCardView(cryptoData: data)
                        }
                    }
                    .padding()
                    .onAppear {
                        fetchCryptoPrices()
                    }
                }
                
                Spacer()
                                
                                NavigationLink(destination: AddHoldingView(holdings: $holdings), isActive: $isAddingHolding) {
                                    EmptyView()
                                }
                                
                               
                                .padding(.bottom)
                                
                                NavigationLink(destination: PortfolioView(holdings: $holdings)) {
                                    Text("Portfolio")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green) // Adjust the color as needed
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground).ignoresSafeArea())
                            .navigationTitle("Crypto Prices")
                        }
                        .overlay(
                            loginView()
                                .opacity(isLoggedIn ? 0 : 1)
                        )
                        .onAppear {
                            startRefreshing()
                        }
                    }
                

    
    private func loginView() -> some View {
        VStack {
            Image(systemName: "bitcoinsign.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)
                .padding(.bottom, 30)
            
            VStack(spacing: 20) {
                TextField("Username", text: $username)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .textContentType(.username)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    .textContentType(.password)
            }
            .padding(.horizontal)
            
            Button(action: {
                // Simulate login
                isLoading = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Simulating network request delay
                    isLoggedIn = true
                    isLoading = false
                }
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(username.isEmpty || password.isEmpty || isLoading)
            }
            .padding(.top, 30)
            
            if isLoading {
                ProgressView("Logging in...")
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Login")
    }
    
    private func fetchCryptoPrices() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,ripple,litecoin,cardano,dogecoin,binancecoin,solana&vs_currencies=usd&include_24hr_change=true") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([String: [String: Double]].self, from: data)
                    DispatchQueue.main.async {
                        self.cryptoData = result.map { (key, value) in
                            CryptoData(
                                id: key,
                                name: key.capitalized,
                                price: value["usd"] ?? 0,
                                priceChange24h: value["usd_24h_change"] ?? 0,
                                marketCap: 1000000000, // Placeholder value or actual value if available
                                volume: 5000000, // Placeholder value or actual value if available
                                circulatingSupply: 100000000 // Placeholder value or actual value if available
                            )
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    private func startRefreshing() {
        Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            fetchCryptoPrices() // Fetch cryptocurrency prices periodically
        }
    }
            }
struct CryptoPricesView: View {
    @State private var cryptoData: [CryptoData] = []
    @State private var isLoading = true
    
    var body: some View {
        if isLoading {
            ProgressView("Loading...")
                .onAppear {
                    fetchCryptoPrices()
                }
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(cryptoData.sorted(by: { $0.price > $1.price })) { data in // Sort by price
                        CryptoCardView(cryptoData: data)
                    }
                }
                .padding()
            }
        }
    }
    
    private func fetchCryptoPrices() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,ripple,litecoin,cardano,dogecoin,binancecoin,solana&vs_currencies=usd&include_24hr_change=true") else {
            print("Invalid URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode([String: [String: Double]].self, from: data)
                    DispatchQueue.main.async {
                        self.cryptoData = result.map { (key, value) in
                            CryptoData(
                                id: key,
                                name: key.capitalized,
                                price: value["usd"] ?? 0,
                                priceChange24h: value["usd_24h_change"] ?? 0,
                                marketCap: 1000000000, // Placeholder value or actual value if available
                                volume: 5000000, // Placeholder value or actual value if available
                                circulatingSupply: 100000000 // Placeholder value or actual value if available
                            )
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }.resume()
    }

}
struct CryptoData: Identifiable {
    let id: String
    let name: String
    let price: Double
    let priceChange24h: Double
    let marketCap: Double
    let volume: Double
    let circulatingSupply: Double
    
    var priceChangeColor: Color {
        return priceChange24h >= 0 ? .green : .red
    }
}


struct CryptoCardView: View {
    let cryptoData: CryptoData
    
    var body: some View {
        NavigationLink(destination: CryptoDetailView(cryptoData: cryptoData)) {
            HStack(spacing: 15) {
                AsyncImage(url: URL(string: coinIconURL(for: cryptoData.name))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                } placeholder: {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(cryptoData.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("$\(String(format: "%.2f", cryptoData.price))")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(cryptoData.priceChangeColor)
                        Text("(\(String(format: "%.2f", cryptoData.priceChange24h))%)")
                            .font(.subheadline)
                            .foregroundColor(cryptoData.priceChangeColor)
                    }
                    
                    // Mini chart example (simplified)
                    LineChart(data: generateSampleData())
                        .frame(height: 20)
                }
                
                Spacer()
                
                Image(systemName: cryptoData.priceChange24h >= 0 ? "arrow.up" : "arrow.down")
                    .foregroundColor(cryptoData.priceChangeColor)
                    .font(.system(size: 20))
                    .rotationEffect(.degrees(abs(cryptoData.priceChange24h) >= 0 ? 0 : 180))
            }
            .padding(15)
            .background(Color(.systemGray6))
            .cornerRadius(15)
            .shadow(radius: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    // Remaining code...


    
    private func coinIconURL(for coinName: String) -> String {
        switch coinName.lowercased() {
            case "bitcoin":
                return "https://cdn-icons-png.flaticon.com/128/5968/5968260.png"
            case "ethereum":
                return "https://cdn-icons-png.flaticon.com/128/14446/14446160.png"
            case "ripple":
                return "https://cdn-icons-png.flaticon.com/128/4821/4821657.png"
            case "litecoin":
                return "https://cdn-icons-png.flaticon.com/128/14446/14446185.png"
            case "cardano":
                return "https://cdn-icons-png.flaticon.com/128/14446/14446142.png"
            case "dogecoin":
                return "https://cdn-icons-png.flaticon.com/128/6557/6557093.png"
            case "polkadot":
                return "https://cdn-icons-png.flaticon.com/128/15301/15301733.png"
        case "solana":
            return "https://cdn-icons-png.flaticon.com/128/15208/15208206.png"
        case "binancecoin":
            return "https://cdn-icons-png.flaticon.com/128/15301/15301504.png"
            default:
                return "https://example.com/questionmark_icon.png"
        }
    }

    
    // Function to generate sample market data for the past 24 hours
    func generateSampleData() -> [Double] {
        let now = Date()
        var currentDate = now.addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        var prices: [Double] = []
        
        while currentDate <= now {
            // Generate random price changes within a reasonable range
            let randomChange = Double.random(in: -1000...1000)
            let previousPrice = prices.last ?? 20000 // Start with a base price of $20,000
            let newPrice = max(1000, previousPrice + randomChange) // Ensure price is at least $1000
            
            prices.append(newPrice)
            currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        }
        
        return prices
    }
}

struct LineChart: View {
    let data: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<2) { index in
                    Path { path in
                        let y = CGFloat(index) * geometry.size.height / 2
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                    .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                };                Path { path in
                    for i in 0..<data.count {
                        let x = (geometry.size.width / CGFloat(data.count)) * CGFloat(i) + (geometry.size.width / CGFloat(data.count * 2)) // Center the data point horizontally
                        let y = geometry.size.height * (1 - CGFloat(data[i]) / CGFloat(data.max() ?? 1))
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .trim(from: 0, to: 1)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: lineColors(from: data)), startPoint: .leading, endPoint: .trailing), // Use a gradient with varying colors
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                .animation(.easeInOut(duration: 1))
            }
        }
        .padding()
    }
    private func lineColors(from data: [Double]) -> [Color] {
        guard let openingPrice = data.first else { return [] } // Get the opening price
        
        return data.map { $0 >= openingPrice ? .green : .red } // Compare each data point to the opening price
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search", text: $text)
                .padding(.horizontal)
            
            Button(action: {
                text = ""
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(.trailing)
        }
        .frame(height: 40)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
struct CryptoDetail {
    let marketCap: Double
    let volume: Double
    let circulatingSupply: Double
    let historicalPrices: [Double] // Example data for historical prices
}
private func generateSampleData() -> [Double] {
    let now = Date()
    var currentDate = now.addingTimeInterval(-24 * 60 * 60) // 24 hours ago
    var prices: [Double] = []
    
    while currentDate <= now {
        // Generate random price changes within a reasonable range
        let randomChange = Double.random(in: -1000...1000)
        let previousPrice = prices.last ?? 20000 // Start with a base price of $20,000
        let newPrice = max(1000, previousPrice + randomChange) // Ensure price is at least $1000
        
        prices.append(newPrice)
        currentDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
    }
    
    return prices
}

struct CryptoDetailView: View {
    let cryptoData: CryptoData
    @State private var showChart = false // Track whether to show the historical price chart
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text(cryptoData.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Price: $\(String(format: "%.2f", cryptoData.price))")
                    .font(.title)
                
                HStack {
                    Text("Price Change (24h):")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.2f", cryptoData.priceChange24h))")
                        .font(.headline)
                        .foregroundColor(cryptoData.priceChangeColor)
                    
                    Image(systemName: cryptoData.priceChange24h >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(cryptoData.priceChangeColor)
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(abs(cryptoData.priceChange24h) >= 0 ? 0 : 180))
                }
                
                HStack {
                    Text("Market Cap:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", cryptoDetail.marketCap))")
                        .font(.headline)
                }
                
                HStack {
                    Text("Volume:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("$\(String(format: "%.2f", cryptoDetail.volume))")
                        .font(.headline)
                }
                
                HStack {
                    Text("Circulating Supply:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.2f", cryptoDetail.circulatingSupply))")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(20)
            .shadow(radius: 5)
            
            Button(action: {
                showChart.toggle()
            }) {
                Text("Show Historical Price Chart")
                    .font(.headline)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            if showChart {
                VStack {
                    Text("Historical Price Chart")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .padding(.bottom, 10)
                    
                    LineChart(data: generateSampleData())
                        .padding()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .shadow(radius: 5)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(cryptoData.name)
    }
    
    private var cryptoDetail: CryptoDetail {
        return CryptoDetail(
            marketCap: 1000000000,
            volume: 5000000,
            circulatingSupply: 100000000,
            historicalPrices: generateSampleData()
        )
    }
}


struct PortfolioView: View {
    @Binding var holdings: [PortfolioItem] // Declare a binding to the holdings array
    @State private var isAddingHolding = false // Add isAddingHolding state variable
    
    init(holdings: Binding<[PortfolioItem]>) { // Define an initializer that accepts a binding
        self._holdings = holdings // Initialize the binding
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(holdings) { item in
                        PortfolioItemRow(item: item)
                    }
                    .onDelete(perform: deleteHoldings)
                }
                
                Button(action: { isAddingHolding = true }) {
                    Text("Add Holding")
                }
                .padding()
                .sheet(isPresented: $isAddingHolding) {
                    AddHoldingView(holdings: $holdings)
                }
            }
            .navigationTitle("Portfolio")
        }
    }
    
    private func deleteHoldings(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
    }
}



struct PortfolioItemRow: View {
    let item: PortfolioItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text("Amount: \(item.amount)")
                    .font(.subheadline)
            }
            Spacer()
            Text("Value: \(item.value)")
        }
    }
}

struct PortfolioItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let value: Double
}
struct AddHoldingView: View {
    @Binding var holdings: [PortfolioItem]
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var amount = ""
    @State private var isNameValid = true
    @State private var isAmountValid = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cryptocurrency")) {
                    TextField("Name", text: $name)
                        .onChange(of: name) { newValue in
                            isNameValid = !newValue.isEmpty
                        }
                        .foregroundColor(isNameValid ? .primary : .red)
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { newValue in
                            isAmountValid = Double(newValue) != nil
                        }
                        .foregroundColor(isAmountValid ? .primary : .red)
                }
            }
            .navigationTitle("Add Holding")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveHolding()
                    }
                    .disabled(!isFormValid())
                }
            }
        }
    }
    
    private func saveHolding() {
        guard let amount = Double(amount) else { return }
        let newValue = 0 // Calculate value based on current price (you need to fetch prices)
        let newHolding = PortfolioItem(name: name, amount: amount, value: Double(newValue))
        holdings.append(newHolding)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty && Double(amount) != nil
    }
}
