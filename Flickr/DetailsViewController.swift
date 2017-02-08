//
//  DetailsViewController.swift
//  Flickr
//
//  Created by Satyam Jaiswal on 2/7/17.
//  Copyright © 2017 Satyam Jaiswal. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {

    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var detailsScrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    
    var movie: NSDictionary!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.detailsScrollView.contentSize = CGSize(width: detailsScrollView.frame.size.width, height: self.infoView.frame.origin.y + self.infoView.frame.size.height)
        
        if let title = movie["original_title"] as? String{
            self.titleLabel.text = title
        }
        
        if let overview = movie["overview"] as? String{
            self.overviewLabel.text = overview
            self.overviewLabel.sizeToFit()
        }
        
        let baseURL = "https://image.tmdb.org/t/p/w500"
        if let filePath = movie["poster_path"] as? String{
            if let posterURL = URL(string: baseURL+filePath){
                self.posterImageView.setImageWith(posterURL)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
