import Foundation

//===

extension Dispatcher
{
    /**
     Schedules transition into a new state for processing.
     
     - Parameter task: Transition (wrapped with state getter and completion) that needs to be scheduled.
     */
    func enqueue(_ task: DeferredTransition<Object>)
    {
        queue.enqueue(task)
        
        //===
        
        processNext()
    }
    
    /**
     Starts processing scheduled transitions, if it's not processing yet.
     */
    private
    func processNext()
    {
        guard
            let object = object,
            let now = core.state as? Core.Ready<Object>,
            let (newState, forcedTransition, completion) = queue.dequeue()
        else
        {
            return
        }
        
        //===
        
        core.state = Core.InTransition(previous: now.current, next: newState)
        
        //===
        
        let changes: () -> Void
        let transition: Transition<Object>
        
        if
            now.current == newState
        {
            changes = { newState.onUpdate?(object) }
            transition = forcedTransition ?? newState.onUpdateTransition
        }
        else
        {
            changes = { newState.onSet(object) }
            transition = forcedTransition ?? newState.onSetTransition
        }
        
        //===
        
        transition.prepare?(object)
        transition.execute(changes) { finished in
            
            transition.complete?(object)
            
            //===
            
            self.core.state = Core.Ready(current: newState)
            
            //===
            
            completion?(finished)
            
            //===
            
            // TODO: Decide here!?
            
//            if
//                Thread.current == Thread.main
//            {
//                self.processNext()
//            }
//            else
//            {
//
//            }
            
            // in case transition was instant
            DispatchQueue.main.async {
                
                self.processNext()
            }
        }
    }
}
