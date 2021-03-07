//
//  FetchingPeopleService.swift
//  PeopleList
//
//  Created by Taha Metin Bayi on 7.03.2021.
//

import Foundation

class FetchingPeopleService {
    
    private enum ResultType {
        case success
        case failure
    }
    
    static let shared = FetchingPeopleService()
    
    private var dispatchGroup = DispatchGroup()
    private var fetchingQueue = DispatchQueue(label: "serial.fetchingQueue")
    
    private var fetchingSet: Set<String?> = Set()
    private var next: String?
    
    func fetchPeople(onSuccess: @escaping ([Person], Bool)->Void, onError: @escaping (FetchError, Bool)->Void, refresh: Bool = false) {
        let next = refresh ? nil : self.next
        guard tryToLockFetching(next: next) else { return }
        sendFetchingRequest(next: next, onSuccess: onSuccess, onError: onError, refresh: refresh)
    }
    
    private func sendFetchingRequest(next: String?, onSuccess: @escaping ([Person], Bool)->Void, onError: @escaping (FetchError, Bool)->Void, refresh: Bool = false) {
        fetchingQueue.async {
            DataSource.fetch(next: next, { response, error in
                let resultType: ResultType = error == nil ? .success : .failure
                switch resultType {
                case .success:
                    guard let response = response else { return }
                    self.next = response.next
                    onSuccess(response.people, refresh)
                case .failure:
                    guard let error = error else { return }
                    onError(error, refresh)
                }
                self.fetchingSet.remove(next)
            })
        }
    }
    
    private func tryToLockFetching(next: String?) -> Bool {
        defer {
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        let isAlreadyFetching = fetchingSet.contains(next)
        if !isAlreadyFetching {
            fetchingSet.insert(next)
        }
        return !isAlreadyFetching
    }
    
}
