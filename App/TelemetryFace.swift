import SwiftUI

struct TelemetryFace: View {
    let snapshot: TelemetrySnapshot
    let demo: Bool
    @Environment(\.isLuminanceReduced) private var dimmed
    private let orange = Color(red:1,green:0.52,blue:0.025)

    var body: some View {
        GeometryReader { available in
            let scale = min(available.size.width / 184, available.size.height / 208)
            VStack(spacing:4) {
                HStack {
                    Text("TELEMETRÍA / 02").font(.system(size:8,weight:.bold,design:.monospaced))
                    Spacer()
                    Text(demo ? "DEMO" : "SALUD").font(.system(size:7,weight:.bold,design:.monospaced))
                }.foregroundStyle(orange)
                TimelineView(.periodic(from:.now,by:60)) { context in
                    SegmentDigits(text:String(format:"%02d:%02d", Calendar.current.component(.hour,from:context.date), Calendar.current.component(.minute,from:context.date)),color:orange)
                }.frame(height:34)
                HStack(spacing:5) {
                    VStack(spacing:8) {
                        Text("ACTIVIDAD").font(.system(size:6,weight:.bold,design:.monospaced))
                        ZStack {
                            Circle().stroke(orange.opacity(0.15),lineWidth:5)
                            Circle().trim(from:0,to:min(max((snapshot.dailyValue(snapshot.steps) ?? 0)/10000,0),1))
                                .stroke(orange,style:StrokeStyle(lineWidth:5,lineCap:.butt)).rotationEffect(.degrees(-90))
                            Image(systemName:"figure.walk").font(.system(size:20))
                        }.frame(width:38,height:38)
                        Text("META\n10 000").font(.system(size:7,weight:.bold,design:.monospaced)).multilineTextAlignment(.center)
                        Image(systemName:"chevron.up.chevron.up").font(.system(size:12,weight:.bold))
                    }
                    .foregroundStyle(orange).frame(width:49,height:131)
                    .background(CutPanel().fill(LinearGradient(colors:[Color(white:0.19),.black,Color(white:0.12)],startPoint:.topLeading,endPoint:.bottomTrailing)))
                    .overlay(CutPanel().stroke(Color.gray,lineWidth:0.8))
                    VStack(spacing:4) {
                        meter("PULSO · ÚLTIMA LECTURA",value:TelemetrySnapshot.number(snapshot.pulse),symbol:"heart.fill")
                        meter("ENERGÍA / KCAL",value:TelemetrySnapshot.number(snapshot.dailyValue(snapshot.kilocalories)),symbol:"flame.fill")
                        meter("DISTANCIA / KM",value:TelemetrySnapshot.number(snapshot.dailyValue(snapshot.kilometers),decimals:1),symbol:"location.fill")
                        meter("PASOS",value:TelemetrySnapshot.number(snapshot.dailyValue(snapshot.steps)),symbol:"figure.walk")
                    }
                }
                HStack {
                    Text(Date(),format:.dateTime.day().month(.abbreviated))
                    Spacer()
                    Text(demo ? "DATOS FICTICIOS" : snapshot.stale() ? "DATOS ANTIGUOS" : "DATOS DE SALUD")
                }.font(.system(size:7,weight:.bold,design:.monospaced)).foregroundStyle(orange)
            }
            .frame(width:184,height:208)
            .scaleEffect(scale,anchor:.center)
            .position(x:available.size.width/2,y:available.size.height/2)
        }
    }

    private func meter(_ title: String,value: String,symbol:String) -> some View {
        VStack(spacing:1) {
            HStack(spacing:2) {
                Image(systemName:symbol)
                Text(title).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength:0)
            }.font(.system(size:5,weight:.bold,design:.monospaced))
                .fixedSize(horizontal:false,vertical:true)
            SegmentDigits(text:value,color:dimmed ? orange : .black).frame(height:16)
        }
        .padding(.horizontal,7).padding(.vertical,4)
        .frame(maxWidth:.infinity)
        .fixedSize(horizontal:false,vertical:true)
        .foregroundStyle(dimmed ? orange : .black)
        .background(CutPanel().fill(LinearGradient(colors:dimmed ? [.black] : [orange,Color(red:1,green:0.68,blue:0.15),orange],startPoint:.topLeading,endPoint:.bottomTrailing)))
        .overlay(CutPanel().stroke(Color.gray,lineWidth:0.8))
        .accessibilityElement(children:.ignore).accessibilityLabel("\(title), \(value)")
    }
}

