import {assert} from 'chai';
import {spy} from 'sinon';
import {Time} from '@lib/services/time.service';

describe('Time', () => {
    let mockDate;
    beforeEach(() => {
        mockDate = {
            getDay: () => {
                return 0;
            }
        };
    });
    describe('#serverTimeGetDay', () => {
        it('returns the day', () => {
            const dateSpy = spy(mockDate, 'getDay');
            Time.serverTimeGetDay(mockDate);
            assert(dateSpy.calledOnce, 'got the day');
        });
    });
});
