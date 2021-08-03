//
//  ContentView.swift
//  HeteroTaskGroups
//
//  Created by Russell Gordon on 2021-08-03.
//

import SwiftUI

struct NewsStory: Identifiable, Decodable {
    let id: Int
    let title: String
    let strap: String
}

struct Score: Decodable {
    let name: String
    let score: Int
}

// What we are hoping to create
struct ViewModel {
    let stories: [NewsStory]
    let scores: [Score]
}

// This is the bit that lets us handle task groups with heterogeneous types
// Associated values to the enum cases
enum FetchResult {
    case newsStories([NewsStory])
    case scores([Score])
}

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
            .task(loadData)
    }
    
    func loadData() async {
        let viewModel = await withThrowingTaskGroup(of: FetchResult.self) { group -> ViewModel in

            group.addTask {
                let url = URL(string: "https://hws.dev/headlines.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode([NewsStory].self, from: data)
                return .newsStories(result)
            }
            
            group.addTask {
                let url = URL(string: "https://hws.dev/scores.json")!
                let (data, _) = try await URLSession.shared.data(from: url)
                let result = try JSONDecoder().decode([Score].self, from: data)
                return .scores(result)
            }

            // Now, what did we actually get back?
            var newsStories = [NewsStory]()
            var scores = [Score]()
            
            
            do {
                // Here we unpack the enum
                // I've got a FetchResult
                // What kind of FetchResult? What's inside you? Scores, OK, take and put in [Scores] array, etc
                for try await value in group {
                    // What is this value? NewsStory? or Score?
                    switch value {
                    case .newsStories(let stories):
                        newsStories = stories
                    case .scores(let downloadedScores):
                        scores = downloadedScores
                    }
                }
            } catch {
                print("Fetch at least partially failed, send back whatever we have so far")
            }
            
            return ViewModel(stories: newsStories, scores: scores)
            
            
        }
        
        print(viewModel.scores)
        print(viewModel.stories)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
