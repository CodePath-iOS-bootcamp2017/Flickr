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

class MoviesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, UIScrollViewDelegate{

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewFlowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let apiKey = "cee559a4a6b70debdcf335be6e319ce0"
    var movieDictionary: [NSDictionary]?
    var filteredMovies: [NSDictionary]?
    var errorCode = 0
    let button = UIButton()
    let refreshControl = UIRefreshControl()
    var endpoint:String!
    var loadingMoreProgressIndicator: InfiniteScrollActivityView?
    var isMoreDataLoading = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.searchBar.delegate = self
        self.loadNavigationBar()
        
        let progressIndicatorFrameTableView = CGRect(x: 0, y: self.tableView.contentSize.height, width: self.tableView.bounds.width, height: InfiniteScrollActivityView.defaultHeight)
        self.loadingMoreProgressIndicator = InfiniteScrollActivityView(frame: progressIndicatorFrameTableView)
        loadingMoreProgressIndicator?.isHidden = true
        self.tableView.addSubview(loadingMoreProgressIndicator!)
        self.collectionView.addSubview(loadingMoreProgressIndicator!)
        
        var insetTableView = self.tableView.contentInset
        insetTableView.bottom += (loadingMoreProgressIndicator?.bounds.height)!
        self.tableView.contentInset = insetTableView
        
        var insetCollectionView = self.collectionView.contentInset
        insetCollectionView.bottom += (loadingMoreProgressIndicator?.bounds.height)!
        self.collectionView.contentInset = insetCollectionView
        
        button.frame = CGRect(x: 0, y: 0, width: 35, height: 25)
        button.setImage(UIImage(named:"listView.png"), for: UIControlState.normal)
        button.addTarget(self, action: #selector(switchView(_:)), for: UIControlEvents.touchDown)
        let barButton = UIBarButtonItem()
        barButton.customView = button
        self.navigationItem.leftBarButtonItem = barButton
        self.loadNavigationBar()
        
        self.collectionViewFlowLayout.scrollDirection = .vertical
        self.collectionViewFlowLayout.minimumInteritemSpacing = 2
        self.collectionViewFlowLayout.minimumLineSpacing = 2
        self.collectionViewFlowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
        loadFromNetwork()
        
        self.tableView.isHidden = true
        self.tableView.alpha = 0
        self.collectionView.alpha = 1
        self.collectionView.isHidden = false
        
        
        refreshControl.addTarget(self, action: #selector(refreshContent(_:)), for: UIControlEvents.valueChanged)
        collectionView.insertSubview(refreshControl, at: 0)
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // overriding methods for table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movieCount = filteredMovies?.count{
            return movieCount
        }else{
            return 0
        }
    }
    
    func loadNavigationBar(){
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.setBackgroundImage(UIImage(named: "Flickr_logo"), for: .default)
            navigationBar.tintColor = UIColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 0.8)
            
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.gray.withAlphaComponent(0.5)
            shadow.shadowOffset = CGSize(width: 2, height: 2)
            shadow.shadowBlurRadius = 4;
            navigationBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFont(ofSize: 22),
                NSForegroundColorAttributeName : UIColor(red: 0.5, green: 0.15, blue: 0.15, alpha: 0.8),
                NSShadowAttributeName : shadow
            ]
            
        }else{
            print("navigationBar not found")
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as? MovieTableViewCell
        if let movie = filteredMovies?[indexPath.row]{
            cell?.titleLabel.text = movie["original_title"] as? String
            cell?.overviewLabel.text = movie["overview"] as? String
            
            let baseURL = "https://image.tmdb.org/t/p/w500"
            if let filePath = movie["poster_path"] as? String{
                let posterURL = URL(string: baseURL+filePath)
                self.fadeInImageAtView(url: posterURL!, posterImageView: (cell?.posterImageView)!)
            }
            
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.errorCode == -1009{
            
            let networkErrorImageView = UIImageView()
            let networkErrorImage = UIImage(named: "network_error")
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
            networkErrorImageView.image = networkErrorImage
            networkErrorImageView.contentMode = UIViewContentMode.scaleAspectFill
            
            self.tableView.backgroundView = networkErrorImageView
            self.tableView.backgroundView?.alpha = 0.2
            
            let networkErrorTapGesture = UITapGestureRecognizer()
            networkErrorTapGesture.addTarget(self, action: #selector(loadFromNetwork))
            self.tableView.backgroundView?.isUserInteractionEnabled = true
            self.tableView.backgroundView?.addGestureRecognizer(networkErrorTapGesture)
            return 0
        }else{
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
            self.tableView.backgroundView?.alpha = 0
            return 1
        }
    }
    
    
    // overriding methods for collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movieCount = filteredMovies?.count{
            return movieCount
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionViewCell", for: indexPath) as! MovieCollectionViewCell
            
        if let movie = filteredMovies?[indexPath.row]{
            let baseURL = "https://image.tmdb.org/t/p/w500"
            if let filePath = movie["poster_path"] as? String{
                let posterURL = URL(string: baseURL+filePath)
                //            cell.posterImageView.setImageWith(posterURL!)
                self.fadeInImageAtView(url: posterURL!, posterImageView: cell.posterImageView)
            }
            
        }

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = self.collectionView.bounds.size.width
        let totalHeight = self.collectionView.bounds.size.height
        
        return CGSize(width: totalWidth/2-2, height: totalHeight/2-2)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if self.errorCode == -1009{
            let networkErrorImageView = UIImageView()
            let networkErrorImage = UIImage(named: "network_error")
            networkErrorImageView.image = networkErrorImage
            networkErrorImageView.contentMode = UIViewContentMode.scaleAspectFill
            
            self.collectionView.backgroundView = networkErrorImageView
            self.collectionView.backgroundView?.alpha = 0.2
            
            let networkErrorTapGesture = UITapGestureRecognizer()
            networkErrorTapGesture.addTarget(self, action: #selector(loadFromNetwork))
            self.collectionView.backgroundView?.isUserInteractionEnabled = true
            self.collectionView.backgroundView?.addGestureRecognizer(networkErrorTapGesture)
            
            return 0
        }else{
            self.collectionView.backgroundView?.alpha = 0
            return 1
        }
    }
    
    // overriding methods for search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if(searchText.isEmpty){
//            print("isEmpty")
            self.filteredMovies = self.movieDictionary
        }else{
//            print("not Empty")
            self.filteredMovies = self.movieDictionary?.filter({ (movie) -> Bool in
                if let title = movie.value(forKey: "original_title") as? String{
                    return (title.range(of: searchText) != nil)
                }
                return false
            })
        }
        self.tableView.reloadData()
        self.collectionView.reloadData()
    }
    
    
    func loadFromNetwork(){
        
        let urlString = "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)"
        print(urlString)
        let url = URL(string: urlString)
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
                    self.filteredMovies = self.movieDictionary
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
    
    func loadMoreData(){
        let parameterString = "page=\((self.movieDictionary?.count)!/20 + 1)"
        let baseURLString = "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)"
        let urlString = "\(baseURLString)&\(parameterString)"
        print(urlString)
        if let url = URL(string:urlString){
            let request = URLRequest(url: url)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
            let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
                if let data = data{
                    if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary{
                        if let additionalPosts = responseDictionary.value(forKeyPath: "results") as? [NSDictionary]{
//                            print(additionalPosts)
                            self.movieDictionary?.append(contentsOf: additionalPosts)
                            self.filteredMovies = self.movieDictionary
                            self.loadingMoreProgressIndicator?.stopAnimating()
                            
                            if(self.collectionView.isHidden){
                                self.tableView.reloadData()
                                print("reloading tableview data")
                            }
                            else{
                                self.collectionView.reloadData()
                            }
                            
                            self.isMoreDataLoading = false
                        }
                    }else{
                        print("json serialization error")
                    }
                }else{
                    print("data is nil")
                }
            })
            task.resume()
        }else{
            print("url is nil")
        }
        
    }
    
    //animation for fading in posters
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
    
    // called on refresh event
    func refreshContent(_ refreshControl: UIRefreshControl){
        self.loadFromNetwork()
        refreshControl.endRefreshing()
    }
    
    //called when view is switched
    func switchView(_ sender: Any) {
        if self.tableView.isHidden {
            self.tableView.isHidden = false
            self.tableView.alpha = 1
            self.collectionView.isHidden = true
            self.collectionView.alpha = 0
            self.tableView.reloadData()
            button.setImage(UIImage(named:"gridView.png"), for: UIControlState.normal)
            tableView.insertSubview(refreshControl, at: 0)
        }else{
            self.tableView.isHidden = true
            self.tableView.alpha = 0
            self.collectionView.alpha = 1
            self.collectionView.isHidden = false
            self.collectionView.reloadData()
            button.setImage(UIImage(named:"listView.png"), for: UIControlState.normal)
            collectionView.insertSubview(refreshControl, at: 0)
        }
    }
    
    // overriding scrollViewDelegate methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if(!isMoreDataLoading){
            if(self.collectionView.isHidden){
                let scrollViewHeight = self.tableView.contentSize.height
                let tableViewHeight = self.tableView.bounds.height
                
                let loadMoreThresholdPosition = scrollViewHeight - tableViewHeight
                
                if(scrollView.contentOffset.y > loadMoreThresholdPosition && scrollView.isDragging){
                    self.isMoreDataLoading = true
                    
                    let frame = CGRect(x: 0, y: self.tableView.contentSize.height, width: self.tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                    self.loadingMoreProgressIndicator?.frame = frame
                    self.loadingMoreProgressIndicator!.startAnimating()
                    
                    loadMoreData()
                }
            }else{
                let scrollViewHeight = self.collectionView.contentSize.height
                let collectionViewHeight = self.collectionView.bounds.height
                
                let loadMoreThresholdPosition = scrollViewHeight - collectionViewHeight
                
                if(scrollView.contentOffset.y > loadMoreThresholdPosition && scrollView.isDragging){
                    self.isMoreDataLoading = true
                    
                    let frame = CGRect(x: 0, y: self.collectionView.contentSize.height, width: self.collectionView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                    self.loadingMoreProgressIndicator?.frame = frame
                    self.loadingMoreProgressIndicator!.startAnimating()
                    
                    loadMoreData()
                }
            }
            
        }
    }
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let tableCell = sender as? MovieTableViewCell{
            let tableIndex = tableView.indexPath(for: tableCell)
            let movie = self.filteredMovies?[(tableIndex?.row)!]
            
            if let detailsViewController = segue.destination as? DetailsViewController{
                detailsViewController.movie = movie
            }
            
            
            
        }else if let collectionCell = sender as? MovieCollectionViewCell {
            let collectionIndex = self.collectionView.indexPath(for: collectionCell)
            let movie = self.filteredMovies?[(collectionIndex?.row)!]
            
            if let detailsViewController = segue.destination as? DetailsViewController{
                detailsViewController.movie = movie
            }
        }
    }
}
