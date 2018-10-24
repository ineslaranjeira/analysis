function outp = dataset2table(D, ses)

% convert ONE dataset into an easy-to-work-with behavioral table
varnames    = regexprep(D.dataset_type, '_ibl_trials.', '');
s           = cell2struct(D.data, varnames);

% add some useful things for behavioral analysis
s.signedContrast = (s.contrastLeft - s.contrastRight) * 100;
s.rt             = s.response_times - s.stimOn_times;
s.correct        = double(sign(s.signedContrast) == s.choice);
s.contrastRight(s.signedContrast == 0) = NaN;
s.trial         = transpose(1:length(s.choice));

% metadata from 'ses'
sesflds = {'subject', 'location', 'lab', 'start_time', 'end_time'};
for sidx = 1:length(sesflds),
    if contains(sesflds{sidx}, 'time'),
        % log start_time and end_time as datetimes in Matlab
        s.(sesflds{sidx}) = repmat(datetime(ses.(sesflds{sidx}){1}, ...
            'inputformat', 'yyyy-MM-dd''T''HH:mm:SS'), length(s.choice), 1);
    else
        s.(sesflds{sidx}) = repmat(ses.(sesflds{sidx}), length(s.choice), 1);
    end
end

% if possible, convert
if ~verLessThan('matlab','8.2')
    outp = struct2table(s);
else
    outp = s;
end

end
