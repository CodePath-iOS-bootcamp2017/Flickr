//
//  DetailsViewController.swift
//  Flickr
//
//  Created by Satyam Jaiswal on 2/7/17.
//  Copyright © 2017 Satyam Jaiswal. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var detailsScrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    @IBOutlet weak var releaseDateLabel: UILabel!
    
    @IBOutlet weak var popularityLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var ratingImageView: UIImageView!
    
    @IBOutlet weak var trailerImageView: UIImageView!
    
    @IBOutlet weak var genreLabel: UILabel!
    
    var movie: NSDictionary!
    var genres: Dictionary? = Dictionary<Int,String>()
    let apiKey = "cee559a4a6b70debdcf335be6e319ce0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.detailsScrollView.delegate = self
//        self.infoView.bounds = CGRect(x: Double(self.detailsScrollView.frame.minX+20), y: Double(self.detailsScrollView.bounds.height-30), width: Double(self.detailsScrollView.bounds.width-40), height: Double(self.detailsScrollView.bounds.height)/2)
////        self.infoView.sizeToFit()
//        self.detailsScrollView.bounds = CGRect(x: 0, y: UIScreen.main.bounds.height/2, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
//        self.detailsScrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        self.detailsScrollView.contentSize.height = 1000
        
        if let title = movie["original_title"] as? String{
            self.titleLabel.text = title
        }
        
        if let overview = movie["overview"] as? String{
            self.overviewLabel.text = overview
            self.overviewLabel.sizeToFit()
        }
        
        if let popularity = movie.value(forKey: "popularity") as? Double{
            print(popularity)
            let popuplarityPercent = Int(popularity)
            self.popularityLabel.text = "\(popuplarityPercent)%"
        }
        
        if let releaseDate = movie.value(forKey: "release_date") as? String{
            self.releaseDateLabel.text = releaseDate
        }
        
        calculateMovieRating()
        loadMovieDetails()
        
        let lowResolutionBaseURL = "https://image.tmdb.org/t/p/w45"
        if let filePath = movie["poster_path"] as? String{
            if let lowResolutionPosterURL = URL(string: lowResolutionBaseURL+filePath){
                let lowResolutionURLRequest = URLRequest(url: lowResolutionPosterURL)
//                self.posterImageView.setImageWith(posterURL)
                self.posterImageView.setImageWith(lowResolutionURLRequest, placeholderImage: nil, success: { (lowResolutionURLRequest, lowResolutionURLResponse, lowResolutionImage) in
                    
                    self.posterImageView.image = lowResolutionImage
                    self.posterImageView.alpha = 0
                    
                    UIView.animate(withDuration: 0.3, animations: {
                            self.posterImageView.alpha = 1.0
                    }, completion: { (success) in
                        let highResolutionBaseURL = "https://image.tmdb.org/t/p/original"
                        let highResolutionPosterURL = URL(string: highResolutionBaseURL+filePath)
                        let highResolutionPosterURLRequest = URLRequest(url: highResolutionPosterURL!)
                        self.posterImageView.setImageWith(highResolutionPosterURLRequest, placeholderImage: lowResolutionImage, success: { (highResolutionPosterRequest, highResolutionPosterResponse, highResolutionImage) in
                            self.posterImageView.image = highResolutionImage
                        }, failure: { (req, res, error) in
                            print(error)
                        })
                        
                    })
                }, failure: { (req, res, error) in
                    print(error)
                })
            }
        }
        
//        loadGenres()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func calculateMovieRating(){
        if let rating = self.movie.value(forKey: "vote_average") as? Double{
            print(rating)
            switch(Int(rating)){
                case 1,2: self.ratingImageView.image = UIImage(named: "1star")
                case 3,4: self.ratingImageView.image = UIImage(named: "2star")
                case 5,6: self.ratingImageView.image = UIImage(named: "3star")
                case 7,8: self.ratingImageView.image = UIImage(named: "4star")
                default: self.ratingImageView.image = UIImage(named: "5star")
            }
        }
    }
    
    func loadGenres(){
        let urlString = "https://api.themoviedb.org/3/genre/movie/list?api_key=\(self.apiKey)"
        let requestURL = URL(string: urlString)
        let request: URLRequest = URLRequest(url: requestURL!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data{
                if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary{
                    if let genreDictionaryArray = responseDictionary.value(forKey: "genres") as? [NSDictionary]{
                        for genre in genreDictionaryArray{
                            let genreId = genre.value(forKey: "id") as! Int
                            let genreName = genre.value(forKey: "name") as! String
                            self.genres?[genreId] = genreName
                        }

                        var genreStr = ""
                        if let genreArr = self.movie?.value(forKey: "genre_ids") as? [Int]{
                            for genre in genreArr{
                                genreStr += " " + (self.genres?[genre]!)!
                            }
                        }
                        
                        self.genreLabel.text = genreStr
                    }
                }
            }
        }
        task.resume()
    }
    
    func loadMovieDetails(){
        if let movieId = self.movie.value(forKey: "id") as? Int{
            let urlString = "https://api.themoviedb.org/3/movie/\(movieId)?api_key=\(apiKey)"
            let requestURL = URL(string: urlString)
            let request: URLRequest = URLRequest(url: requestURL!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let session: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request) { (data, response, error) in
                if let data = data{
                    if let responseDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary{
                        if let genreDictionaryArray = responseDictionary.value(forKey: "genres") as? [NSDictionary]{
                            var genreStr = ""
                            for genre in genreDictionaryArray{
                                if let genreName = genre.value(forKey: "name") as? String{
                                    genreStr += " " + genreName
                                }
                            }
                            self.genreLabel.text = genreStr
                        }
                        
                        if let runtime = responseDictionary.value(forKey: "runtime") as? Int{
                            self.durationLabel.text = "\(runtime)mins"
                        }
                    }
                }
            }
            task.resume()
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
