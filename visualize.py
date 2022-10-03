import mloop.visualizations as mlv
import matplotlib.pyplot as plt

mlv.configure_plots()
mlv.show_all_default_visualizations_from_archive(
    controller_filename='/Volumes/ni_lab/KRbLab/M_Loop1.5/TransferFolder/M-LOOP_archives/controller_archive_2022-09-23_22-47.txt', 

    learner_filename='/Volumes/ni_lab/KRbLab/M_Loop1.5/TransferFolder/M-LOOP_archives/controller_archive_2022-09-23_22-47.txt'
)
plt.show()