@isTest
private class TriggerHandlerTestClass {
//
//	static testmethod void loopCountTest() {
//		TriggerHandler.LoopCount lc = new TriggerHandler.LoopCount();
//        System.assertEquals(5, lc.getMax());
//        System.assertEquals(0, lc.getCount());
//
//        TriggerHandler.LoopCount lc2 = new TriggerHandler.LoopCount(10);
//        System.assertEquals(10, lc2.getMax());
//        System.assertEquals(0, lc2.getCount());
//
//        lc2.setMax(1);
//        System.assertEquals(1, lc2.getMax());
//
//        lc2.increment();
//        System.assertEquals(false, lc2.exceeded());
//
//        lc2.increment();
//        System.assertEquals(true, lc2.exceeded());
//    }
//
//    static testmethod void handlerLoopCounts() {
//        TriggerHandler handler = new TriggerHandler();
//
//        handler.setMaxLoopCount(10);
//        handler.setMaxLoopCount(20);
//        System.assertEquals(20, TriggerHandler.loopCountMap.get(handler.getHandlerName()).getMax());
//
//        handler.clearMaxLoopCount();
//        System.assertEquals(-1, TriggerHandler.loopCountMap.get(handler.getHandlerName()).getMax());
//    }
//
//    static testmethod void handlerExceededException() {
//        TriggerHandler handler = new TriggerHandler();
//
//        handler.setMaxLoopCount(1);
//        System.assertEquals(1, TriggerHandler.loopCountMap.get(handler.getHandlerName()).getMax());
//        TriggerHandler.loopCountMap.get(handler.getHandlerName()).increment();
//
//        try{
//            handler.addToLoopCount();
//        }catch(Exception e){
//            System.assertEquals('Maximum loop count of 1 reached in ' + handler.getHandlerName(),e.getMessage());
//        }
//    }
//
//    static testmethod void handlerBypass() {
//        TriggerHandler.bypass('TEST BYPASS');
//        System.assertEquals(true,TriggerHandler.isBypassed('TEST BYPASS'));
//        System.assertEquals(false,TriggerHandler.isBypassed('TEST BYPASS FAIL'));
//
//        TriggerHandler.clearBypass('TEST BYPASS');
//        System.assertEquals(false,TriggerHandler.isBypassed('TEST BYPASS'));
//
//        TriggerHandler.bypass('TEST BYPASS');
//        TriggerHandler.bypass('TEST BYPASS 2');
//        TriggerHandler.clearAllBypasses();
//        System.assertEquals(false,TriggerHandler.isBypassed('TEST BYPASS'));
//        System.assertEquals(false,TriggerHandler.isBypassed('TEST BYPASS2'));
//    }
}