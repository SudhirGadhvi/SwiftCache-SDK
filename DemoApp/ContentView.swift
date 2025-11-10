//
//  ContentView.swift
//  SwiftCache Demo
//
//  Created by Sudhir Gadhvi
//

import SwiftUI
import SwiftCache

struct ContentView: View {
    
    @State private var showingStats = false
    
    let imageURLs: [URL] = [
        URL(string: "https://picsum.photos/400/400?random=1")!,
        URL(string: "https://picsum.photos/400/400?random=2")!,
        URL(string: "https://picsum.photos/400/400?random=3")!,
        URL(string: "https://picsum.photos/400/400?random=4")!,
        URL(string: "https://picsum.photos/400/400?random=5")!,
        URL(string: "https://picsum.photos/400/400?random=6")!,
        URL(string: "https://picsum.photos/400/400?random=7")!,
        URL(string: "https://picsum.photos/400/400?random=8")!,
    ]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(imageURLs, id: \.self) { url in
                        CachedImage(url: url) {
                            ProgressView()
                                .frame(height: 200)
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .cornerRadius(8)
                        .frame(height: 200)
                    }
                }
                .padding()
            }
            .navigationTitle("SwiftCache Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Stats") {
                        showingStats = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        SwiftCache.shared.clearCache()
                    }
                }
            }
            .sheet(isPresented: $showingStats) {
                StatsView()
            }
        }
        .onAppear {
            Task {
                await SwiftCache.shared.configure { config in
                    config.enableAnalytics = true
                    config.enableProgressiveLoading = true
                }
            }
        }
    }
}

struct StatsView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var metrics: CacheMetrics?
    @State private var cacheSize: (memory: Int, disk: Int64)?
    
    var body: some View {
        NavigationView {
            List {
                Section("Performance") {
                    if let metrics = metrics {
                        HStack {
                            Text("Total Requests")
                            Spacer()
                            Text("\(metrics.totalRequests)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Memory Hits")
                            Spacer()
                            Text("\(metrics.memoryHits)")
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Disk Hits")
                            Spacer()
                            Text("\(metrics.diskHits)")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Network Hits")
                            Spacer()
                            Text("\(metrics.networkHits)")
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Hit Rate")
                            Spacer()
                            Text(String(format: "%.1f%%", metrics.hitRate * 100))
                                .foregroundColor(.green)
                        }
                        
                        HStack {
                            Text("Avg Memory Load")
                            Spacer()
                            Text(String(format: "%.2fms", metrics.averageMemoryLoadTime * 1000))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Avg Disk Load")
                            Spacer()
                            Text(String(format: "%.2fms", metrics.averageDiskLoadTime * 1000))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Avg Network Load")
                            Spacer()
                            Text(String(format: "%.2fms", metrics.averageNetworkLoadTime * 1000))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                
                Section("Storage") {
                    if let cacheSize = cacheSize {
                        HStack {
                            Text("Memory Cache")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: Int64(cacheSize.memory), countStyle: .memory))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Disk Cache")
                            Spacer()
                            Text(ByteCountFormatter.string(fromByteCount: cacheSize.disk, countStyle: .file))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                
                Section {
                    Button("Reset Metrics") {
                        Task {
                            await SwiftCache.shared.resetMetrics()
                            await loadStats()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("SwiftCache Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadStats()
            }
        }
    }
    
    private func loadStats() async {
        metrics = await SwiftCache.shared.getMetrics()
        cacheSize = await SwiftCache.shared.getCacheSize()
    }
}

#Preview {
    ContentView()
}

