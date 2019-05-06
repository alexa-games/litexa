/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved. 
 * These materials are licensed as "Restricted Program Materials" under the Program Materials 
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service. 
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html. 
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized 
 * terms not defined in this file have the meanings given to them in the Agreement. 
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import {assert, expect} from 'chai';
import {spy, stub} from 'sinon';
import {addNumbers, todayName} from '@lib/components/utils';
import {TimeService} from '@lib/services/time.service';

describe('utils', () => {
    describe('#todayName', () => {
        let mockTimeService: TimeService;
        beforeEach(() => {
            mockTimeService = {
                serverTimeGetDay: () => {
                    return 0;
                }
            };
        });

        it('returns the days of the week correctly', () => {
            let timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(0);
            expect(todayName(mockTimeService)).to.equal('Sunday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(1);
            expect(todayName(mockTimeService)).to.equal('Monday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(2);
            expect(todayName(mockTimeService)).to.equal('Tuesday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(3);
            expect(todayName(mockTimeService)).to.equal('Wednesday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(4);
            expect(todayName(mockTimeService)).to.equal('Thursday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(5);
            expect(todayName(mockTimeService)).to.equal('Friday');
            timeStub.restore();

            timeStub = stub(mockTimeService, 'serverTimeGetDay').returns(6);
            expect(todayName(mockTimeService)).to.equal('Saturday');
            timeStub.restore();
        });

        it('makes a call to the time service for the day', () => {
            let timeSpy = spy(mockTimeService, 'serverTimeGetDay');
            todayName(mockTimeService);
            assert(timeSpy.calledOnce, 'made a call to the time service for the server day');
        })
    });
    describe('#addNumbers', () => {
        it('defaults to 0', () => {
            expect(addNumbers()).to.equal(0);
        });
        it('sums correctly', () => {
            expect(addNumbers(1,2,3)).to.equal(6);
        });
    });
});
