/*
 * Copyright 2017-present Sirono LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * Dispatches trigger-based events to implementations of <code>TriggerHandler</code> based on the current trigger context.
 *
 * @see Trigger
 * @see lp_TriggerHandlerFactory
 * @see TriggerHandler
 */
public with sharing class lp_TriggerHandlerDispatcher {
    private static final lp_Logger LOG = lp_Logger.getInstance(lp_TriggerHandlerDispatcher.class);

    public static void dispatch(Type factoryType) {
        lp_TriggerContext triggerContext = new lp_TriggerContext(Trigger.isExecuting,
                Trigger.isInsert,
                Trigger.isUpdate,
                Trigger.isDelete,
                Trigger.isBefore,
                Trigger.isAfter,
                Trigger.isUndelete,
                Trigger.new,
                Trigger.newMap,
                Trigger.old,
                Trigger.oldMap,
                Trigger.size);
        dispatch(factoryType, triggerContext);
    }

    /**
     * Dispatch the current trigger event to a trigger handler created using the specified factory.
     *
     * @param factoryType the class for the trigger handler factory used to create the trigger handler
     */
    public static void dispatch(Type factoryType, lp_TriggerContext triggerContext) {
        // Make sure this is running in the context of a trigger
        if (!triggerContext.isExecuting) {
            String message = 'Trigger handler must only be invoked in the context of an executing trigger.';
            LOG.error(message);
            throw new lp_IllegalStateException(message);
        }

        // Make sure a factory type was provided
        if (factoryType == null) {
            String message = 'Factory type must be specified.';
            LOG.error(message);
            throw new lp_IllegalArgumentException(message);
        }

        // Instantiate the trigger handler factory
        Object instance = factoryType.newInstance();
        if (!(instance instanceof lp_TriggerHandlerFactory)) {
            String message = 'Trigger handler factory must implement ' + lp_TriggerHandlerFactory.class.getName() + '.';
            LOG.error(message);
            throw new lp_IllegalArgumentException(message);
        }
        lp_TriggerHandlerFactory factory = (lp_TriggerHandlerFactory) instance;

        // Create the trigger handler
        lp_TriggerHandler handler = factory.create(triggerContext.isDelete ? triggerContext.oldList : triggerContext.newList, triggerContext.oldMap);
        if (handler == null) {
            String message = 'The trigger handler factory must create a trigger handler.';
            LOG.error(message);
            throw new lp_IllegalStateException(message);
        }

        // Call the appropriate trigger handler method
        if (triggerContext.isBefore && triggerContext.isInsert) {
            handler.beforeInsert();
        } else if (triggerContext.isAfter && triggerContext.isInsert) {
            handler.afterInsert();
        } else if (triggerContext.isBefore && triggerContext.isUpdate) {
            handler.beforeUpdate();
        } else if (triggerContext.isAfter && triggerContext.isUpdate) {
            handler.afterUpdate();
        } else if (triggerContext.isBefore && triggerContext.isDelete) {
            handler.beforeDelete();
        } else if (triggerContext.isAfter && triggerContext.isDelete) {
            handler.afterDelete();
        } else if (triggerContext.isAfter && triggerContext.isUndelete) {
            handler.afterUndelete();
        }
    }
}