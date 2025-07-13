//
//  LimitedQueueTest.swift
//  Edmund
//
//  Created by Hollan Sellars on 7/12/25.
//

import Testing
import Edmund

struct LimitedQueueTest {
    @Test
    func limitedQueue() {
        var queue = LimitedQueue<Int>(capacity: 3, with: 0);
        
        #expect(queue.append(1) == nil)
        #expect(queue.append(2) == nil)
        #expect(queue.append(3) == nil);
        
        #expect(queue.front == 1);
        #expect(queue.back  == 3);
        
        #expect(queue.append(4) == 1);
        #expect(queue.append(5) == 2);
        
        #expect(queue.front == 3);
        #expect(queue.back  == 5);
    }
}
