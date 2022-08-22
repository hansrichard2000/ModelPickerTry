//
//  ContentView.swift
//  ModelPickerTry
//
//  Created by Hans Richard Alim Natadjaja on 17/08/22.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    @State private var isDeleteModel = false
    
    private var models: [Model] = {
        // Dynamically get our model filenames
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try?
                filemanager.contentsOfDirectory(atPath: path) else {
            return []
        }
        
        var availableModels: [Model] = []
        for filename in files where filename.hasSuffix("usdz") {
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            
            let model = Model(modelName: modelName)
            availableModels.append(model)
        }
        
        return availableModels
    }()
    
    //    var models: [String] = ["fender_stratocaster", "teapot", "toy_biplane", "toy_robot_vintage"]
    
    var body: some View {
        ZStack(alignment: .bottom){
            ARViewContainer(modelConfirmedForReplacement: self.$modelConfirmedForPlacement, isDeleteModel: self.$isDeleteModel)
            
            if self.isPlacementEnabled {
                PlacementButtonView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, modelConfirmedForPlacement: self.$modelConfirmedForPlacement, isDeleteModel: self.$isDeleteModel)
            }else{
                ModelPickerView(isPlacementEnabled: self.$isPlacementEnabled, selectedModel: self.$selectedModel, models: self.models)
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForReplacement: Model?
    @Binding var isDeleteModel: Bool
    func makeUIView(context: Context) -> ARView {
        
        let arView = CustomARView(frame: .zero)
        arView.enableObjectRemoval()
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let model = self.modelConfirmedForReplacement {
            if(isDeleteModel == true){
                
            }
            else{
                if let modelEntity = model.modelEntity {
                    print("DEBUG: adding model to scene - \(model.modelName)")
                    modelEntity.generateCollisionShapes(recursive: true)
                    uiView.installGestures([.translation,.rotation,.scale],for: modelEntity)
                    //ADDS 3D
                    
                    let anchorEntity = AnchorEntity(plane: .any)
                    anchorEntity.name = "something"
//                    anchorEntity.addChild(modelEntity.clone(recursive: true))
                    anchorEntity.addChild(modelEntity)
                    uiView.scene.addAnchor(anchorEntity)
                    
// Try Debugging, cause it wont work if its clone
//                    uiView.debugOptions.showPhysics
                    
                }else{
                    print("DEBUG: unable to load modelEntity for - \(model.modelName)")
                }
            }
            
            
            //            let filename = modelName + ".usdz"
            
            //            let modelEntity = try! ModelEntity.loadModel(named: filename)
            //
            //            let anchorEntity = AnchorEntity(plane: .any)
            //            anchorEntity.addChild(modelEntity)
            //
            //            uiView.scene.addAnchor(anchorEntity)
            
            DispatchQueue.main.async {
                self.modelConfirmedForReplacement = nil
            }
        }
        
    }
    
}

class CustomARView: ARView {
//    enum FocusStyleChoices {
//        case classic
//        case material
//        case color
//    }
//
//    /// Style to be displayed in the example
//    let focusStyle: FocusStyleChoices = .classic
//    var focusEntity: FocusEntity?
//    required init(frame frameRect: CGRect) {
//        super.init(frame: frameRect)
//        self.setupConfig()
//
//        switch self.focusStyle {
//        case .color:
//            self.focusEntity = FocusEntity(on: self, focus: .plane)
//        case .material:
//            do {
//                let onColor: MaterialColorParameter = try .texture(.load(named: "Add"))
//                let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
//                self.focusEntity = FocusEntity(
//                    on: self,
//                    style: .colored(
//                        onColor: onColor, offColor: offColor,
//                        nonTrackingColor: offColor
//                    )
//                )
//            } catch {
//                self.focusEntity = FocusEntity(on: self, focus: .classic)
//                print("Unable to load plane textures")
//                print(error.localizedDescription)
//            }
//        default:
//            self.focusEntity = FocusEntity(on: self, focus: .classic)
//        }
//    }
//
//    @objc required dynamic init?(coder decoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    func setupConfig() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        self.session.run(config)
    }
    
    
    
    func enableObjectRemoval(){
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:)))
        self.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    @objc func handleLongPress(recognizer : UILongPressGestureRecognizer){
        let location = recognizer.location(in: self)
        
        if let entity = self.entity(at: location) {
            if let anchorEntity = entity.anchor, anchorEntity.name == "something"{
                anchorEntity.removeFromParent()
                print("Removed anchor with name: " + anchorEntity.name)
            }
            
        }
        
    }
    
}

extension CustomARView:FocusEntityDelegate {
    func toTrackingState() {
        print("tracking")
    }
    
    func toInitializingState() {
        print("Initializing")
    }
}


struct ModelPickerView: View {
    //#1
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    
    var models: [Model]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 30){
                ForEach(0 ..< self.models.count) { index in
                    Button(action: {
                        print("DEBUG: selected model with name: \(self.models[index].modelName)")
                        
                        self.selectedModel = self.models[index]
                        
                        self.isPlacementEnabled = true
                    }) {
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                            .background(Color.white)
                            .cornerRadius(12)
                    }.buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonView: View{
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    @Binding var isDeleteModel: Bool
    var body: some View{
        HStack{
            //Cancel Button
            Button(action: {
                print("DEBUG: Cancel model placement.")
                
                self.isPlacementEnabled = false
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            })
            
            //Confirm Button
            Button(action: {
                print("DEBUG: model placement confirmed.")
                
                self.modelConfirmedForPlacement = self.selectedModel
                
                self.resetPlacementParameters()
            }, label: {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            })
            Button(action: {
                print("DEBUG: model Delete confirmed.")
                self.isDeleteModel = true
                self.modelConfirmedForPlacement = self.selectedModel
                
                self.resetPlacementParameters()
            }, label: {
                Image(systemName: "trash")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            })
        }
    }
    
    func resetPlacementParameters(){
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
