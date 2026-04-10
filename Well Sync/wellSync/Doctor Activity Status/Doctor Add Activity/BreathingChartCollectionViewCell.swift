//
//  BreathingChartCollectionViewCell.swift
//  sample
//
//  Created by Pranjal on 01/04/26.
//

import Charts
import UIKit
import DGCharts


class BreathingChartCollectionViewCell: UICollectionViewCell {
   
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var chartView: LineChartView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cardView.layer.cornerRadius = 20
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
        cardView.layer.shadowRadius = 6
        setupChart()
    }

    func setupChart() {

        let entries = [
            ChartDataEntry(x:0,y:2),
            ChartDataEntry(x:1,y:6),
            ChartDataEntry(x:2,y:3),
            ChartDataEntry(x:3,y:7),
            ChartDataEntry(x:4,y:1),
            ChartDataEntry(x:5,y:5),
            ChartDataEntry(x:6,y:4)
        ]

        let dataSet = LineChartDataSet(entries: entries)

        dataSet.mode = .cubicBezier
        dataSet.lineWidth = 3
        dataSet.setColor(.systemTeal)
        dataSet.circleColors = [.systemTeal]
        dataSet.drawValuesEnabled = false

        chartView.data = LineChartData(dataSet: dataSet)

        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.chartDescription.enabled = false
        chartView.xAxis.drawGridLinesEnabled = false
        
        chartView.leftAxis.gridColor = UIColor.systemGray4
        chartView.xAxis.gridColor = UIColor.systemGray4
        chartView.leftAxis.gridLineWidth = 0.5
        chartView.xAxis.gridLineWidth = 0.5
        chartView.drawBordersEnabled = false

        chartView.noDataText = ""

        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: days)
        chartView.xAxis.granularity = 1
    }
}
