function out=findsamples(filename,seriesvec,tol,spillover,tr,dummy_volumes,ftdir)

if numel(tr)==1
    tr=tr*ones(size(seriesvec));
end


if numel(dummy_volumes)==1
    dummy_volumes=dummy_volumes*ones(size(seriesvec));
end




addpath(ftdir)

trg=ft_read_event(filename);
hdr=ft_read_header(filename);



trignum=0;
for i=1:length(trg)
    if strcmp(trg(i).value,'R128')
        trignum=trignum+1;
        samplevec(trignum)=trg(i).sample;
    end
end


%SAMPLEVEC=[samplevec(1)-(FS*DUMMY_VOLUMES*TR):samplevec(NUM_VOLUMES)-2+(FS*TR)];


volvec=diff([0 find(abs(diff(diff(samplevec)))>tol) length(samplevec)]);
volvec(volvec==1)=[];
volvec=volvec+1;
volvec(end)=volvec(end)-1;

volvec_orig=volvec;

%make a testvec to find out which volumes to be discarded
testvec=zeros(size(volvec));
testvec(1:length(seriesvec))=seriesvec;

if length(testvec)>length(volvec)
        disp('I think the recording is missing the beginning please remove the first element in the seriesvec')
        out='length(testvec)>length(volvec)';
        return
end
for i=1:length(testvec) % find out which of the elements in volvec needs to be discarded
    %discardvec=find((volvec-testvec)<0)
    discardvec=find((volvec-testvec)~=0);
    if  ~isempty(discardvec)
        discardvol=discardvec(1);
        if discardvol
            testvec(discardvol+1:end)=testvec(discardvol:end-1);% make a space for the 0
            testvec(discardvol)=0;
            volvec(discardvol)=0;
        end
    end
end

discardseries=find(volvec==0);

startsamplevec_idx=[0 cumsum(volvec_orig(1:end-1))]+1;
startsamplevec_idx(discardseries)=[];
%error for sub 27 (og94?)+46(missing EEG?)
for i=1:length(seriesvec)
    samples=samplevec(startsamplevec_idx(i))-dummy_volumes(i)*tr(i)*hdr.Fs:samplevec(startsamplevec_idx(i))+hdr.Fs*seriesvec(i)*tr(i)+(spillover*hdr.Fs)-1;
    out.samples{i}=samples;
    out.sampleslength{i}=length(samples);
    out.sampleslength_vols{i}=length(samples)/hdr.Fs/tr(i);
end



out.trg=trg;
out.samplevec=samplevec;
out.volvec=volvec;
out.volvec_orig=volvec_orig;
out.testvec=testvec;
out.discardseries=discardseries;
out.startsamplevec_idx=startsamplevec_idx;
out.hdr=hdr;
