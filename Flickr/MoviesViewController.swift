//
//  MoviesViewController.swift
//  Flickr
//
//  Created by Satyam Jaiswal on 1/31/17.
//  Copyright © 2017 Satyam Jaiswal. All rights reserved.
//

import UIKit
import AFNetworking
import SVProgressHUD

class MoviesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    
    
    var movieDictionary: [NSDictionary]?
    var errorCode = 0
    let button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 25)
        button.setImage(UIImage(named:"listView.png"), for: UIControlState.normal)
        button.addTarget(self, action: #selector(switchView(_:)), for: UIControlEvents.touchDown)
        let barButton = UIBarButtonItem()
        barButton.customView = button
        self.navigationItem.leftBarButtonItem = barButton
        
        self.collectionViewFlowLayout.scrollDirection = .vertical
        self.collectionViewFlowLayout.minimumInteritemSpacing = 2
        self.collectionViewFlowLayout.minimumLineSpacing = 2
        self.collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        loadFromNetwork()
        
        self.tableView.isHidden = true
        self.collectionView.alpha = 1
        self.collectionView.isHidden = false
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshContent(_:)), for: UIControlEvents.valueChanged)
        tableView.insertSubview(refreshControl, at: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movieCount = movieDictionary?.count{
            return movieCount
        }else{
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieTableViewCell
        if let movie = movieDictionary?[indexPath.row]{
            cell?.titleLabel.text = movie["original_title"] as? String
            cell?.overviewLabel.text = movie["overview"] as? String
            
            let baseURL = "https://image.tmdb.org/t/p/w500"
            let filePath = movie["poster_path"] as? String
            let posterURL = URL(string: baseURL+filePath!)
            self.fadeInImageAtView(url: posterURL!, posterImageView: (cell?.posterImageView)!)
//            cell?.posterImageView.setImageWith(posterURL!)
//            cell.textLabel?.text = movie["original_title"] as? String
        }
        
        return cell!
    }
    
    func fadeInImageAtView(url: URL, posterImageView: UIImageView) -> Void{
        let imageRequest = URLRequest(url: url)
        posterImageView.setImageWith(imageRequest, placeholderImage: nil, success: { (imageRequest, response, image) in
            if response != nil{
                posterImageView.alpha = 0
                posterImageView.image = image
                UIView.animate(withDuration: 0.3, animations: {
                    posterImageView.alpha = 1
                })
            }else{
                posterImageView.image = image
            }
        }) { (imageRequest, response, error) in
            print(error)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.errorCode == -1009{
            /*
            let networkErrorLabel = UILabel()
            networkErrorLabel.text = "Network Error! :("
            networkErrorLabel.textAlignment = NSTextAlignment.center
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
            self.tableView.backgroundView = networkErrorLabel
            */
            let networkErrorImageView = UIImageView()
            let networkErrorImage = UIImage(named: "network_error")
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
            networkErrorImageView.image = networkErrorImage
            networkErrorImageView.alpha = 0.2
            
            let screenSize = UIScreen.main.bounds
            networkErrorImageView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height*0.2)
            self.tableView.backgroundView = networkErrorImageView
            return 0
        }else{
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movieCount = movieDictionary?.count{
            return movieCount
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionViewCell", for: indexPath) as! MovieCollectionViewCell
            
        if let movie = movieDictionary?[indexPath.row]{
            let baseURL = "https://image.tmdb.org/t/p/w500"
            let filePath = movie["poster_path"] as? String
            let posterURL = URL(string: baseURL+filePath!)
//            cell.posterImageView.setImageWith(posterURL!)
            self.fadeInImageAtView(url: posterURL!, posterImageView: cell.posterImageView)
        }
            
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = self.collectionView.bounds.size.width
        let totalHeight = self.collectionView.bounds.size.height
        
        return CGSize(width: totalWidth/2-2, height: totalHeight/3-2)
    }
    
    func loadFromNetwork(){
        let apiKey = "cee559a4a6b70debdcf335be6e319ce0"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        self.errorCode = 0
        SVProgressHUD.show()
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let err = error as? NSError{
                
                SVProgressHUD.dismiss()
                print(err.code)
                
                if err.code == -1009{
                    print("network error")
                    self.errorCode = -1009
                    
                    if self.tableView.isHidden {
                        self.collectionView.reloadData()
                    }else{
                        self.tableView.reloadData()
                    }
                }
            }
            else if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    
                    SVProgressHUD.dismiss()
                    
                    self.movieDictionary = dataDictionary["results"] as? [NSDictionary]
                    //                    print(dataDictionary)
                    if self.tableView.isHidden {
                        self.collectionView.reloadData()
                    }else{
                        self.tableView.reloadData()
                    }
                    
                }
            }
        }
        task.resume()
    }
    
    func refreshContent(_ refreshControl: UIRefreshControl){
        self.loadFromNetwork()
        refreshControl.endRefreshing()
    }
    
    func switchView(_ sender: Any) {
        if self.tableView.isHidden {
            self.tableView.isHidden = false
            self.tableView.alpha = 1
            self.collectionView.isHidden = true
            self.tableView.reloadData()
            button.setImage(UIImage(named:"gridView.png"), for: UIControlState.normal)
        }else{
            self.tableView.isHidden = true
            self.collectionView.alpha = 1
            self.collectionView.isHidden = false
            self.collectionView.reloadData()
            button.setImage(UIImage(named:"listView.png"), for: UIControlState.normal)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
