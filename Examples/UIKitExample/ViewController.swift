//
//  ViewController.swift
//  UIKitExample
//
//  Created by Sudhir Gadhvi on 06/01/2025.
//  Copyright © 2025 Sudhir Gadhvi. All rights reserved.
//

import UIKit
import SwiftCache

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: (view.bounds.width - 30) / 2, height: 200)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    private lazy var clearButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Clear Cache", style: .plain, target: self, action: #selector(clearCache))
    }()
    
    private lazy var statsButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Stats", style: .plain, target: self, action: #selector(showStats))
    }()
    
    // MARK: - Data
    
    private let imageURLs: [URL] = [
        URL(string: "https://picsum.photos/400/400?random=1")!,
        URL(string: "https://picsum.photos/400/400?random=2")!,
        URL(string: "https://picsum.photos/400/400?random=3")!,
        URL(string: "https://picsum.photos/400/400?random=4")!,
        URL(string: "https://picsum.photos/400/400?random=5")!,
        URL(string: "https://picsum.photos/400/400?random=6")!,
        URL(string: "https://picsum.photos/400/400?random=7")!,
        URL(string: "https://picsum.photos/400/400?random=8")!,
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "SwiftCache UIKit Example"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItems = [statsButton, clearButton]
        
        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Configure SwiftCache
        SwiftCache.shared.configure { config in
            config.enableAnalytics = true
            config.enableProgressiveLoading = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func clearCache() {
        SwiftCache.shared.clearCache()
        collectionView.reloadData()
        
        let alert = UIAlertController(
            title: "Cache Cleared",
            message: "All cached images have been removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func showStats() {
        let metrics = SwiftCache.shared.getMetrics()
        let (memSize, diskSize) = SwiftCache.shared.getCacheSize()
        
        let message = """
        Total Requests: \(metrics.totalRequests)
        Memory Hits: \(metrics.memoryHits)
        Disk Hits: \(metrics.diskHits)
        Network Hits: \(metrics.networkHits)
        Hit Rate: \(String(format: "%.1f%%", metrics.hitRate * 100))
        Avg Load Time: \(String(format: "%.2f", metrics.averageLoadTime * 1000))ms
        
        Memory Cache: \(ByteCountFormatter.string(fromByteCount: Int64(memSize), countStyle: .memory))
        Disk Cache: \(ByteCountFormatter.string(fromByteCount: diskSize, countStyle: .file))
        """
        
        let alert = UIAlertController(
            title: "SwiftCache Statistics",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            SwiftCache.shared.resetMetrics()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let url = imageURLs[indexPath.item]
        cell.configure(with: url)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - ImageCell

class ImageCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray6
        return iv
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        return ai
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with url: URL) {
        imageView.image = nil
        activityIndicator.startAnimating()
        
        var wrapper = imageView.sc
        wrapper.setImage(with: url, placeholder: nil) { [weak self] result in
            self?.activityIndicator.stopAnimating()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sc.cancelLoad()
        imageView.image = nil
        activityIndicator.stopAnimating()
    }
}

