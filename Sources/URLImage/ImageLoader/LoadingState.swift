//
//  LoadingState.swift
//  
//
//  Created by Dmytro Anokhin on 29/09/2019.
//

enum LoadingState : Hashable {

    /// Initial state after the object was created
    case initial

    /// Loading is scheduled and about to start shortly after delay
    case scheduled

    /// Loading is in progress
    case loading

    case finishing

    /// Successfully loaded and decoded data
    case finished

    /// Failed to load or decode data
    case failed

    /// Cancelling
    case cancelling

    /// Cancelled
    case cancelled

    /** Map of valid transitions.

        Each transition has "from" and "to" states.  Key in the map is "from" state. Value is a set of possible "to" states. Together this indicates all possible transitions for a state.

        Allowing transition from `finished`, `failed`, and  `cancelled` states back to `scheduled` state enables reloading data.
    */
    private static let transitions: [LoadingState: Set<LoadingState>] = [
        .initial   : [ .scheduled ],
        .scheduled  : [ .loading, .finishing, finished, .cancelling ],
        .loading   : [ .finishing, .failed, .cancelling ],
        .finishing : [ .finished, .failed ],
        .finished  : [ .scheduled ],
        .failed    : [ .scheduled ],
        .cancelling : [ .cancelled ],
        .cancelled : [ .scheduled ]
    ]

    /** Verifies if transition from `self` to `state` is possible.
    */
    func canTransition(to state: LoadingState) -> Bool {
        return Self.transitions[self]!.contains(state)
    }
}
