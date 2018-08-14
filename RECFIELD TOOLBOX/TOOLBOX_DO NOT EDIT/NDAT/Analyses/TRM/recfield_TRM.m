function ParamData = recfield_TRM(PEHM,options,BackgroundFiringRates)

% Binsize, PEHM
% clear all ;
ParamData=[];
Binsize = options.bin ;

% for each neuron
for j = 1:size(PEHM,2)
    % for each event
    for i = 1:size(PEHM,3)
        % smooth the peri event matrix
        [PeriEventMatrixSmoothed]=smoothperieventmatrix((PEHM(:,:,i))');
        PeriEventMatrixSmoothed = PeriEventMatrixSmoothed' ;
%         CurrMatrix = PeriEventMatrixSmoothed((options.pretime/options.bin)+1:end,j);
        CurrMatrix = PeriEventMatrixSmoothed(:,j);
        OrigMatrix = PEHM(:,j,i);
        
        % to calculate the background average, we use the pre window of
        % to find the threshold.
%         PEHMBackground = PEHM(:,j,i);
PEHMBackground = CurrMatrix;
%         BackgroundAvg=mean(PEHMBackground);
%         BackgroundSTD=std(PEHMBackground);
BackgroundAvg = mean(CurrMatrix) ; %spikes/bin/trial
BackgroundSTD = std(CurrMatrix) ; 

        % define threshold based off of 99 % confidence interval
        Threshold=BackgroundAvg+2.58*BackgroundSTD/(sqrt(length(CurrMatrix)));
        
        % define the peak region around the peak response
        PeakResponse = max(CurrMatrix);
        PeakResponseIndex = max(find(CurrMatrix==PeakResponse));
        
        % find the limits of the response
        % lower limit
        if PeakResponseIndex<2
            k = PeakResponseIndex ;
        else
            for k= 1:(PeakResponseIndex-1)
                if CurrMatrix(PeakResponseIndex-k)>= Threshold
                    % continue
                elseif CurrMatrix(PeakResponseIndex-k)< Threshold
                    break ;
                end
                
            end
        end
        %disp(k) ;
        Index1 = PeakResponseIndex-k+1 ;
        % upper limit
        if PeakResponseIndex == length(CurrMatrix)
            m = PeakResponseIndex ;
        else
            for m = (PeakResponseIndex+1):length(CurrMatrix)
                if CurrMatrix(m)>=Threshold
                    %continue
                elseif CurrMatrix(m)<Threshold
                    break ;
                end
            end
        end
        %disp(m) ;
        Index2 = m-1;
        
        
        % Background average
        BackgroundFiringRate = (sum(PEHMBackground))*200/length(PEHMBackground) ; % spikes/sec 
%         BackgroundFiringRate = BackgroundFiringRates(j); %spikes/sec %from the whole trial. 
        % Response Duration
        ResponseDurationSecs = (Index2-Index1)*Binsize ; %#ok<NASGU> % in seconds
        % Response Magnitude
        RMSpikes = sum(OrigMatrix(Index1:Index2));  % spikes per trial
        % Response Magnitude Background subtracted
        RM_BSub = RMSpikes - ((BackgroundFiringRate/1000)*(Index2-Index1));
        % Peak Response
        PRSpikes =  max(OrigMatrix(Index1:Index2));% in spikes per trial in one bin
        PRIndex = find(OrigMatrix(Index1:Index2)==PRSpikes, 1, 'last' );
        % Latencies
        FBL = (Index1*Binsize) ;  % in seconds from start of window, so 0.250 s will be footfall latency
        LBL = (Index2*Binsize) ; % in seconds from start of window
        PL = FBL+ PRIndex*Binsize ; % in seconds from start of window
        
        
        % if there are less than 3 significant bins ( over 99% CI ) , not a
        % significant response
        
        if isempty(Index1:Index2)
            %disp('empty response');
            BfrSpikesPerBin = 0 ;
            ResponseDurationSecs =0 ;
            RMSpikes = 0;
            RM_BSub = 0 ;
            PRSpikes =0;
            FBL = 0 ;
            LBL = 0 ;
            PL = 0 ;
            
        elseif length(Index1:Index2)<3
            
            BfrSpikesPerBin = 0 ;
            ResponseDurationSecs =0 ;
            RMSpikes = 0;
            RM_BSub = 0 ;
            PRSpikes =0;
            FBL = 0 ;
            LBL = 0 ;
            PL = 0 ;
            
        end
        
        BackgroundAvg = BackgroundAvg/options.bin; %spikes/second calculated using the PSTH
        Parameters(i,:) = [RMSpikes PRSpikes FBL LBL PL BackgroundFiringRate BackgroundAvg i j] ;
    end
    toel= find(Parameters(:,1)==0);
    Parameters(toel,:)=[];
    PRF = find(Parameters(:,1)==max(Parameters(:,1)), 1, 'last' );
    NRM=Parameters(:,1)/Parameters(PRF,1);
    [NRM,b]=sort(NRM,'descend');
    Parameters = [/NRM,Parameters(b,:),repmat(PRF,length(b),1),repmat(length(b),length(b),1)];
    %     Neuron = j ;
    %     WindowType = {'TRM'} ;
    %         [pn fn ext] = fileparts(filenames);
    %         fn = {fn} ;
    %         dots = strfind(fn{1},'.');
    %         Date=fn{1}(1:(dots(1)-1));
    %         Animal = fn{1}((dots(1)+1:dots(2)-1));
    %         Day = fn{1}((dots(3)+1):end);
    %
    %         ParamDataTemp = dataset({Parameters,'RMSpikes','RM_BackgroundSubtracted','PRSpikes','ResponseDurationSecs','BfrSpikesPerBin','FBL','LBL','PL'},{Neuron,'Neuron'},{PRF,'PRF'},{WindowType,'Window'},{fn,'filename'},{Date,'Date'},{Animal,'Animal'},{Day,'Day'});
    %         try
    %             ParamData  = vertcat(ParamData,ParamDataTemp);
    %         catch
    %             ParamData = ParamDataTemp ;
    %         end
    ParamData=[ParamData;Parameters];
    clear Parameters
end
