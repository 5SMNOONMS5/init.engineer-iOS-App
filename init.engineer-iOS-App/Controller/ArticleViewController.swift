//
//  ArticleViewController.swift
//  init.engineer-iOS-App
//
//  Created by horo on 6/7/20.
//  Copyright © 2020 Kantai Developer. All rights reserved.
//

import UIKit
import KaobeiAPI
import GoogleMobileAds

class ArticleViewController: UIViewController {
    
    @IBOutlet weak var articleTitleLabel: UILabel!
    @IBOutlet weak var articleImageView: UIImageView!
    @IBOutlet weak var articleImageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var articleContentTextView: UITextView!
    @IBOutlet weak var primaryFacebookLikeLabel: UILabel!
    @IBOutlet weak var primaryFacebookShareLabel: UILabel!
    @IBOutlet weak var secondaryFacebookLikeLabel: UILabel!
    @IBOutlet weak var secondaryFacebookShareLabel: UILabel!
    @IBOutlet weak var plurkLikeLabel: UILabel!
    @IBOutlet weak var plurkShareLabel: UILabel!
    @IBOutlet weak var twitterLikeLabel: UILabel!
    @IBOutlet weak var twitterShareLabel: UILabel!
    
    
    @IBOutlet weak var commentListTable: UITableView!
    
    var commentList = [Comment]()
    
    var articleID: Int?
    var count = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        self.commentListTable.delegate = self
//        self.commentListTable.dataSource = self
//        self.commentListTable.allowsSelection = false
        guard let id = self.articleID else { return } //back to article list
        
        articleTitleLabel.text = K.tagConvert(from: id)
        
        let detailRequest = KBGetArticleDetail(id: id)
        
        KaobeiConnection.sendRequest(api: detailRequest) { [weak self] (response) in
            switch response.result {
                case .success(let data):
                    self?.articleContentTextView.text = data.data.content
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let articleImage = try UIImage(data: Data(contentsOf: URL(string: data.data.image)!))
                            DispatchQueue.main.async {
                                self?.loadArticleImage(articleImage)
                            }
                        } catch is Error {
                            
                        }
                    }
                    break
                case .failure(_):
                    break
            }
        }
        
        let statsRequest = KBGetArticleStats(id: id)
        
        KaobeiConnection.sendRequest(api: statsRequest) { [weak self] (response) in
            switch response.result {
                case .success(let data):
                    for item in data.data {
                        if item.type == "twitter" {
                            self?.twitterLikeLabel.text = "♥︎ \(item.like)"
                            self?.twitterShareLabel.text = "↻ \(item.share)"
                        } else if item.type == "plurk" {
                            self?.plurkLikeLabel.text = "♥︎ \(item.like)"
                            self?.plurkShareLabel.text = "↻ \(item.share)"
                        } else if item.type == "facebook" {
                            if item.connections == "primary" {
                                self?.primaryFacebookLikeLabel.text = "♥︎ \(item.like)"
                                self?.primaryFacebookShareLabel.text = "↻ \(item.share)"
                            } else if item.connections == "secondary" {
                                self?.secondaryFacebookLikeLabel.text = "♥︎ \(item.like)"
                                self?.secondaryFacebookShareLabel.text = "↻ \(item.share)"
                            }
                        }
                    }
                   break
                case .failure(_):
                   break
            }
        }
        
        let commentRequest = KBGetArticleComments(id: id)
        
//        KaobeiConnection.sendRequest(api: commentRequest) { [weak self] (response) in
//            switch response.result {
//                case .success(let data):
//                    self?.commentList.append(contentsOf: data.data)
//                    self?.count += 1
//                    self?.commentListTable.reloadData()
//                    break
//                case .failure(_):
//                    break
//            }
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func loadArticleImage(_ presentImage: UIImage?) {
        if let presentImage = presentImage {
            let ratio = presentImage.size.width / presentImage.size.height                      // 計算圖片寬高比
            let newHeight = articleImageView.frame.width / ratio
            articleImageViewHeight.constant = newHeight                              // 計算 UIImageView 高度
            view.layoutIfNeeded()
            articleImageView.image = presentImage
            articleImageView.isHidden = false                                                   // 顯示圖片並解除隱藏
        }
    }
    

    
}

extension ArticleViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.commentList.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.commentListTable.dequeueReusableCell(withIdentifier: "comment") as! UITableViewCell
        cell.textLabel?.text = self.commentList[indexPath.row].content
        cell.textLabel?.textColor = .white
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let h: CGFloat = CGFloat((self.commentList[indexPath.row].content.count / 10)) * 20.0
        return h
    }
}
