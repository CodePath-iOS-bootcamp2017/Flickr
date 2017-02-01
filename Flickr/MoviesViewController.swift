//
//  MoviesViewController.swift
//  Flickr
//
//  Created by Satyam Jaiswal on 1/31/17.
//  Copyright © 2017 Satyam Jaiswal. All rights reserved.
//

import UIKit
import AFNetworking

class MoviesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var movieDictionary: [NSDictionary]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        let apiKey = "cee559a4a6b70debdcf335be6e319ce0"
        let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing?api_key=\(apiKey)")
        let request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    self.movieDictionary = dataDictionary["results"] as? [NSDictionary]
//                    print(dataDictionary)
                    self.tableView.reloadData()
                }
            }
        }
        task.resume()
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
            cell?.posterImageView.setImageWith(posterURL!)
//            cell.textLabel?.text = movie["original_title"] as? String
        }
        
        return cell!
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
