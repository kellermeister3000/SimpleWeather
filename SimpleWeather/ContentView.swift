//
//  ContentView.swift
//  SimpleWeather
//
//  Created by Philip Keller on 3/2/23.
//
import Charts
import CoreLocation
import SwiftUI
import WeatherKit

extension Measurement where UnitType == UnitTemperature {
    func narrowFormatted() -> String {
        self.formatted(.measurement(width: .narrow))
    }
}

struct ContentView: View {
    @State private var currentSymbol: String?
    @State private var conditions: String?
    
    @State private var currentTemperature: Measurement<UnitTemperature>?
    @State private var todayHighTemperature: Measurement<UnitTemperature>?
    @State private var todayLowTemperature: Measurement<UnitTemperature>?
    
    @State private var hourForecast: [HourWeather]?
    
    var body: some View {
        ScrollView {
            VStack {
                if let currentSymbol {
                    Image(systemName: currentSymbol)
                        .font(.system(size: 200, weight: .light))
                }
                
                if let currentTemperature {
                    Text(currentTemperature.narrowFormatted())
                        .font(.system(size: 144, weight: .bold))
                }
                
                if let conditions {
                    Text(conditions)
                        .font(.title)
                }
                
                if let todayHighTemperature, let todayLowTemperature {
                    Text("H:\(todayHighTemperature.narrowFormatted()) L:\(todayLowTemperature.narrowFormatted())")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.black.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            
            if let hourForecast {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(hourForecast.prefix(upTo: 24), id: \.date) { hour in
                            VStack {
                                Text(hour.date.formatted(.dateTime.hour()))
                                
                                Image(systemName: hour.symbolName)
                                    .frame(width: 50, height: 30)
                                
                                Text(hour.temperature.narrowFormatted())
                            }
                        }
                    }
                    .padding()
                }
                .background(.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
                
                VStack {
                    Chart(hourForecast.prefix(upTo: 12), id: \.date) { hour in
                        PointMark(
                            x: .value("Time", hour.date, unit: .hour),
                            y: .value("Chance of rain", hour.precipitationChance)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 100)
                    .foregroundStyle(.cyan.gradient)
                    .chartYScale(domain: 0...1)
                    .chartYAxis(.hidden)
                }
                .padding()
                .background(.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            }
        }
        .background(.linearGradient(colors: [.blue, Color(hue: 0.6, saturation: 0.8, brightness: 0.5)], startPoint: .top, endPoint: .bottom))
        .preferredColorScheme(.dark)
        .symbolVariant(.fill)
        .symbolRenderingMode(.multicolor)
        .task {
            loadWeather()
        }
    }
    
    func loadWeather() {
        Task {
            let location = CLLocation(latitude: 51.51, longitude: -0.13)
            let weather = try await WeatherService.shared.weather(for: location)
            
            currentSymbol = weather.currentWeather.symbolName
            conditions = weather.currentWeather.condition.description
            currentTemperature = weather.currentWeather.temperature
            hourForecast = weather.hourlyForecast.filter{ $0.date > .now }
            
            if let today = weather.dailyForecast.first {
                todayLowTemperature = today.lowTemperature
                todayHighTemperature = today.highTemperature
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
