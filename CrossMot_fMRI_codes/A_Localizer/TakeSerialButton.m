%% Wait One Serial Button

function [sbutton,secs]= TakeSerialButton(SerPor)
    %fprintf (1,'%s\n', 'TakeSerialButton')

   sbutton=0;
   secs=0;
   while (SerPor.BytesAvailable)
       if sbutton==0 
           sbutton = str2num(fscanf(SerPor,'%c',1));  % read serial buffer
           secs = GetSecs;                            % CB added this line, to take the time
           if sbutton==5                              % check if it is a MR trigger  
               sbutton = 0;                           % if trigger, ignored
           end
       else
           junk = fscanf(SerPor,'%c',1); 
       end     
   end

end

    
