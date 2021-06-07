//
//  ViewController.swift
//  MyCars
//
//  Created by Ivan Akulov on 08/02/20.
//  Copyright © 2020 Ivan Akulov. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    var car: Car?
    lazy var dateFomatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .none
        return df
    }()
    
    
    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            updateSegmentControl()
            segmentedControl.selectedSegmentTintColor = .white
            let whiteTitleTextAttribute = [NSAttributedString.Key.foregroundColor: UIColor.white]
            let blackTitleTextAttribute = [NSAttributedString.Key.foregroundColor: UIColor.black]
            
            UISegmentedControl.appearance().setTitleTextAttributes(whiteTitleTextAttribute, for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes(blackTitleTextAttribute, for: .selected)
        }
    }
    @IBOutlet weak var markLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var lastTimeStartedLabel: UILabel!
    @IBOutlet weak var numberOfTripsLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var myChoiceImageView: UIImageView!
    
    @IBAction func segmentedCtrlPressed(_ sender: UISegmentedControl) {
        updateSegmentControl()
    }
    
    @IBAction func startEnginePressed(_ sender: UIButton) {
        car?.timesDriven += 1
        car?.lastStarted = Date()
        do {
            try context.save()
            insertDataFrom(selectedCar: car!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func rateItPressed(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Rate it", message: "Rate this car", preferredStyle: .alert)
        let rateAction = UIAlertAction(title: "Rate", style: .default) { action in
            if let text = alertController.textFields?.first?.text {
                self.updateRating(rating: (text as NSString).doubleValue)
            }
        }
        let cancelAction = UIAlertAction(title: "CAncel", style: .default, handler: nil)
        
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }
        
        alertController.addAction(rateAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func updateSegmentControl() {
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        guard let mark = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex) else {return}
        fetchRequest.predicate = NSPredicate(format: "mark == %@", mark)
        do {
            let results = try context.fetch(fetchRequest)
            car = results.first
            if let veicle = car {
                insertDataFrom(selectedCar: veicle)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    private func updateRating(rating: Double) {
        car?.rating = rating
        
        do {
            try context.save()
            insertDataFrom(selectedCar: car!)
        } catch let error as NSError {
            let alertController = UIAlertController(title: "Wrong value", message: "WrongInput", preferredStyle: .alert)
            let alerAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(alerAction)
            present(alertController, animated: true, completion: nil)
            print(error.localizedDescription)
        }
    }
    private func insertDataFrom(selectedCar car: Car) {
        guard let carImage = car.imageData else {return}
        carImageView.image = UIImage(data: carImage)
        markLabel.text = car.mark
        modelLabel.text = car.model
        myChoiceImageView.isHidden = !(car.myChoise)
        ratingLabel.text = "Rating: \(car.rating) / 10"
        numberOfTripsLabel.text = "Number of trips: \(car.timesDriven)"
        lastTimeStartedLabel.text = "Last time started: \(dateFomatter.string(from: car.lastStarted!))"
        segmentedControl.backgroundColor = car.tintColor as? UIColor
    }
    private func getDataFromFile() {
        
        let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "mark != nil")
        
        var records = 0
        
        do {
            records = try context.count(for: fetchRequest)
            print("is data there already")
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        guard records == 0 else {
            return
        }
        guard let pathToFile = Bundle.main.path(forResource: "data", ofType: "plist"), let dataArray = NSArray(contentsOfFile: pathToFile) else {
            return
        }
        for dictionary in dataArray {
            let entity = NSEntityDescription.entity(forEntityName: "Car", in: context)
            let car = NSManagedObject(entity: entity!, insertInto: context) as! Car
            
            let carDictionary = dictionary as! [String: AnyObject]
            car.mark = carDictionary["mark"] as? String
            car.model = carDictionary["model"] as? String
            car.rating = carDictionary["rating"] as! Double
            car.lastStarted = carDictionary["lastStarted"] as? Date
            car.timesDriven = carDictionary["timesDriven"] as! Int16
            car.myChoise = carDictionary["myChoice"] as! Bool
            let imageName = carDictionary["imageName"] as! String
            let image = UIImage(named: imageName)
            let imageData = image!.pngData()
            car.imageData = imageData
            
            if let colorDictionary = carDictionary["tintColor"] as? [String: Float] {
                car.tintColor = getColor(colorDictionary: colorDictionary)
            }
        }
    }
    private func getColor(colorDictionary: [String: Float])->UIColor {
        guard let red = colorDictionary["red"], let green = colorDictionary["green"], let blue = colorDictionary["blue"] else {
            return UIColor()
        }
        return UIColor(red: CGFloat(red / 255), green: CGFloat(green / 255), blue: CGFloat(blue / 255), alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getDataFromFile()
        
       
        
    }
    
}

