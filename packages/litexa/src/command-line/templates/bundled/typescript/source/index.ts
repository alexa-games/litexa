import * as utils from './components/utils';
import {Time} from './services/time.service';

const litexaFunctions = {
    todayName: utils.todayName,
    getDay: Time.serverTimeGetDay
};

export = litexaFunctions;

