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
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(imageURLs, id: \.self) { url in
                        CachedImage(url: url) {
                            ProgressView()
                                .frame(height: 200)
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        .task {
            await SwiftCache.shared.configure { config in
                config.enableAnalytics = true
                config.enableProgressiveLoading = true
            }
        }
    }
}

struct StatsView: View {
    
    @Environment(\.dismiss) var dismiss
    @State private var metrics: CacheMetrics?
    @State private var cacheSize: (memory: Int, disk: Int64)?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Performance") {
                    if let metrics = metrics {
                        LabeledContent("Total Requests") {
                            Text("\(metrics.totalRequests)")
                        }
                        
                        LabeledContent("Memory Hits") {
                            Text("\(metrics.memoryHits)")
                                .foregroundStyle(.green)
                        }
                        
                        LabeledContent("Disk Hits") {
                            Text("\(metrics.diskHits)")
                                .foregroundStyle(.blue)
                        }
                        
                        LabeledContent("Network Hits") {
                            Text("\(metrics.networkHits)")
                                .foregroundStyle(.orange)
                        }
                        
                        LabeledContent("Hit Rate") {
                            Text(String(format: "%.1f%%", metrics.hitRate * 100))
                                .foregroundStyle(.green)
                        }
                        
                        LabeledContent("Avg Memory Load") {
                            Text(String(format: "%.2fms", metrics.averageMemoryLoadTime * 1000))
                        }
                        
                        LabeledContent("Avg Disk Load") {
                            Text(String(format: "%.2fms", metrics.averageDiskLoadTime * 1000))
                        }
                        
                        LabeledContent("Avg Network Load") {
                            Text(String(format: "%.2fms", metrics.averageNetworkLoadTime * 1000))
                        }
                    } else {
                        ProgressView()
                    }
                }
                
                Section("Storage") {
                    if let cacheSize = cacheSize {
                        LabeledContent("Memory Cache") {
                            Text(ByteCountFormatter.string(fromByteCount: Int64(cacheSize.memory), countStyle: .memory))
                        }
                        
                        LabeledContent("Disk Cache") {
                            Text(ByteCountFormatter.string(fromByteCount: cacheSize.disk, countStyle: .file))
                        }
                    } else {
                        ProgressView()
                    }
                }
                
                Section {
                    Button("Reset Metrics", role: .destructive) {
                        Task {
                            await SwiftCache.shared.resetMetrics()
                            await loadStats()
                        }
                    }
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

