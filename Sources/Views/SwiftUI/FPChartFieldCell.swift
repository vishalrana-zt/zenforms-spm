import SwiftUI

struct FPChartFieldCell: View {
    let displayName: String
    var isNoChartData: Bool = true
    var linChartView:LineChartView? = nil
    var onBottomBtnClicked: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            SwiftUI.Text(displayName)
                .font(.headline)
                .foregroundColor(Color("ZT-Black"))
           
            if isNoChartData{
                HStack {
                    Spacer()
                    SwiftUI.Text(FPLocalizationHelper.localize("lbl_No_chart_data"))
                        .font(.footnote)
                    Spacer()
                }
                .frame(height: 150)
            }else {
                if let linChartView = linChartView{
                    linChartView
                        .frame(height: 240)
                        .offset(x: -10, y: 0)
                }
            }
            
            Button(action: {
                onBottomBtnClicked?()
            }) {
                SwiftUI.Text(FPLocalizationHelper.localize("lbl_ViewEdit"))
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color("BT-Primary"))
                    )
            }
        }
        .padding([.vertical, .leading], 10)
        .background(Color.white)
    }
}

#Preview {
    FPChartFieldCell(
        displayName: "Chart 1212",
        onBottomBtnClicked: { print("Button tapped") }
    )
}

extension FPUtility {
    func renderSwiftChart(dictValue:[String:Any], xLbls:[String]) -> LineChartView {
        var arrSChartData = [LineChartDataSet]()
        if let arrDatasets = dictValue["datasets"] as? [[String:Any]]{
            arrDatasets.indices.forEach { dIndex in
                if let dataset  = arrDatasets[safe:dIndex],  let valueData = dataset["data"] as? [String]{
                    let dataValues = valueData.map { Double($0) ?? 0.0}
                    var arrData = [LineChartData]()
                    dataValues.indices.forEach { dIndex in
                        let nValue = LineChartData(x: Double(xLbls[safe:dIndex] ?? "0") ?? 0.0, y: dataValues[dIndex])
                        arrData.append(nValue)
                    }
                    var datasetColr  =   UIColor.random
                    if let hexColor = dataset["borderColor"]  as? String, !hexColor.contains("rgb"){
                        datasetColr = FPUtility.colorwithHexString(hexColor)
                    }
                    let nDataSet = LineChartDataSet(label: dataset["label"] as? String ?? "", data: arrData, lineColor: Color(uiColor: datasetColr))
                    arrSChartData.append(nDataSet)
                }
            }
        }
        
       
        // Create the SwiftUI Chart with dynamic data
        let linechartView = LineChartView(data: arrSChartData, chartTitle: dictValue["chartTitle"] as? String  ?? "", xAxislabel: dictValue["xAxisLabel"] as? String  ?? "", yAxislabel: dictValue["yAxisLabel"] as? String  ?? "", plotBothValue: true)
        
        return linechartView
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
